import Foundation
@preconcurrency import Combine
import Domain

#if os(iOS)
import UIKit
import BackgroundTasks
#endif

/// グローバルタイマー管理サービスの実装
/// アプリ全体で単一のタイマーを管理し、バックグラウンド動作と永続化に対応
@MainActor
public final class GlobalTimerService: GlobalTimerServiceProtocol {
    // MARK: - Published Properties
    @Published private var currentTimerState: TimerState?
    
    // MARK: - Private Properties
    private let intervalTimerUseCase: IntervalTimerUseCaseProtocol
    private let notificationUseCase: TimerNotificationUseCaseProtocol
    private let backgroundTimerService: BackgroundTimerServiceProtocol
    private let persistenceService: TimerPersistenceServiceProtocol
    private let liveActivityService: LiveActivityServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTaskId: String?
    private var currentExerciseName: String?
    private var isAppInBackground = false
    
    // MARK: - Public Properties
    public var currentTimer: AnyPublisher<TimerState?, Never> {
        $currentTimerState.eraseToAnyPublisher()
    }
    
    public var isTimerActive: Bool {
        currentTimerState?.isActive ?? false
    }
    
    // MARK: - Initialization
    public init(
        intervalTimerUseCase: IntervalTimerUseCaseProtocol,
        notificationUseCase: TimerNotificationUseCaseProtocol,
        backgroundTimerService: BackgroundTimerServiceProtocol,
        persistenceService: TimerPersistenceServiceProtocol,
        liveActivityService: LiveActivityServiceProtocol
    ) {
        self.intervalTimerUseCase = intervalTimerUseCase
        self.notificationUseCase = notificationUseCase
        self.backgroundTimerService = backgroundTimerService
        self.persistenceService = persistenceService
        self.liveActivityService = liveActivityService
        
        setupTimerObservation()
        setupAppLifecycleObservation()
        restoreTimerStateIfNeeded()
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Public Methods
public extension GlobalTimerService {
    func startGlobalTimer(duration: TimeInterval, exerciseId: UUID) {
        // 前のタイマーが完了状態で表示中の場合はクリア
        if let currentTimer = currentTimerState,
           currentTimer.status == .completed && currentTimer.shouldPersistAfterCompletion {
            clearGlobalTimer()
        }
        
        // 新しいタイマーを設定
        intervalTimerUseCase.setTimer(duration: duration, exerciseId: exerciseId)
        
        // タイマーを開始
        intervalTimerUseCase.startTimer()
        
        // バックグラウンドタスクを開始
        startBackgroundTaskIfNeeded()
        
        print("[GlobalTimerService] Timer started - Duration: \(duration)s, ExerciseID: \(exerciseId)")
    }
    
    func startGlobalTimer(duration: TimeInterval, exerciseId: UUID, exerciseName: String?) {
        // 種目名を保存
        currentExerciseName = exerciseName
        
        // 通常のタイマー開始処理
        startGlobalTimer(duration: duration, exerciseId: exerciseId)
    }
    
    func pauseGlobalTimer() {
        guard currentTimerState?.status == .running else { return }
        intervalTimerUseCase.pauseTimer()
        cancelBackgroundNotification()
        endBackgroundTaskIfNeeded()
        
        print("[GlobalTimerService] Timer paused")
    }
    
    func resumeGlobalTimer() {
        guard let currentTimer = currentTimerState else { return }
        
        // 完了状態から再開する場合は新しいタイマーとして扱う
        if currentTimer.status == .completed {
            intervalTimerUseCase.startTimer()
        } else if currentTimer.status == .paused {
            intervalTimerUseCase.startTimer()
        }
        
        startBackgroundTaskIfNeeded()
        scheduleBackgroundNotification()
        
        print("[GlobalTimerService] Timer resumed")
    }
    
    func resetGlobalTimer() {
        intervalTimerUseCase.resetTimer()
        cancelBackgroundNotification()
        endBackgroundTaskIfNeeded()
        
        // Live Activityを終了
        Task {
            try? await liveActivityService.endTimerActivity()
        }
        
        print("[GlobalTimerService] Timer reset")
    }
    
    func clearGlobalTimer() {
        intervalTimerUseCase.resetTimer()
        cancelBackgroundNotification()
        endBackgroundTaskIfNeeded()
        persistenceService.clearTimerState()
        currentTimerState = nil
        currentExerciseName = nil
        
        // Live Activityを終了
        Task {
            try? await liveActivityService.endTimerActivity()
        }
        
        print("[GlobalTimerService] Timer cleared completely")
    }
    
    func adjustGlobalTimer(minutes: Int) {
        guard currentTimerState != nil else { return }
        intervalTimerUseCase.adjustTimer(minutes: minutes)
        
        // タイマー実行中の場合は通知を再スケジュール
        if isTimerActive {
            scheduleBackgroundNotification()
        }
        
        print("[GlobalTimerService] Timer adjusted by \(minutes) minutes")
    }
    
    func syncWithCurrentTime() {
        intervalTimerUseCase.syncWithCurrentTime()
        
        print("[GlobalTimerService] Timer synced with current time")
    }
    
    func scheduleBackgroundNotification() {
        guard let timer = currentTimerState,
              timer.isActive,
              timer.remainingTime > 0 else { return }
        
        notificationUseCase.scheduleBackgroundNotification(remainingTime: timer.remainingTime)
        
        print("[GlobalTimerService] Background notification scheduled for \(timer.remainingTime)s")
    }
    
    func cancelBackgroundNotification() {
        notificationUseCase.cancelScheduledNotifications()
        
        print("[GlobalTimerService] Background notification cancelled")
    }
}

// MARK: - Private Methods
private extension GlobalTimerService {
    func setupTimerObservation() {
        intervalTimerUseCase.timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTimerState in
                self?.handleTimerStateUpdate(newTimerState)
            }
            .store(in: &cancellables)
    }
    
    func handleTimerStateUpdate(_ newTimerState: TimerState) {
        let previousState = currentTimerState
        currentTimerState = newTimerState
        
        // タイマー状態を永続化
        persistenceService.saveTimerState(newTimerState)
        
        // Live Activity更新処理（状態変更時のみ）
        if shouldUpdateLiveActivity(newState: newTimerState, previousState: previousState) {
            handleLiveActivityUpdate(newTimerState: newTimerState, previousState: previousState)
        }
        
        // タイマー完了時の処理
        if newTimerState.isCompleted && previousState?.status == .running {
            handleTimerCompletion()
        }
        
        // タイマー開始時の処理
        if newTimerState.status == .running && previousState?.status != .running {
            startBackgroundTaskIfNeeded()
            scheduleBackgroundNotification()
        }
        
        // タイマー停止時の処理
        if newTimerState.status != .running && previousState?.status == .running {
            endBackgroundTaskIfNeeded()
        }
        
        print("[GlobalTimerService] Timer state updated: \(newTimerState.status), remaining: \(newTimerState.formattedRemainingTime)")
    }
    
    func handleLiveActivityUpdate(newTimerState: TimerState, previousState: TimerState?) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // タイマー開始時またはLiveActivityが未開始の場合: Live Activityを開始
                if newTimerState.status == .running && (!self.liveActivityService.isActivityActive || previousState?.status != .running) {
                    print("[GlobalTimerService] Starting Live Activity - Timer: \(newTimerState.formattedRemainingTime), Exercise: \(self.currentExerciseName ?? "Unknown")")
                    
                    try await self.liveActivityService.startTimerActivity(
                        timerState: newTimerState,
                        exerciseName: self.currentExerciseName
                    )
                    print("[GlobalTimerService] Live Activity started successfully")
                }
                // タイマー一時停止時: Live Activityを更新
                else if newTimerState.status == .paused && previousState?.status == .running && self.liveActivityService.isActivityActive {
                    try await self.liveActivityService.updateTimerActivity(timerState: newTimerState)
                    print("[GlobalTimerService] Live Activity updated - paused at: \(newTimerState.formattedRemainingTime)")
                }
                // タイマー再開時: Live Activityを更新
                else if newTimerState.status == .running && previousState?.status == .paused && self.liveActivityService.isActivityActive {
                    try await self.liveActivityService.updateTimerActivity(timerState: newTimerState)
                    print("[GlobalTimerService] Live Activity updated - resumed at: \(newTimerState.formattedRemainingTime)")
                }
                // タイマー完了時: Live Activityを終了（遅延あり）
                else if newTimerState.status == .completed && previousState?.status == .running {
                    print("[GlobalTimerService] Timer completed - updating Live Activity and scheduling end")
                    
                    // 完了状態を一度更新してから終了
                    try await self.liveActivityService.updateTimerActivity(timerState: newTimerState)
                    
                    // 5秒後に自動終了
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        Task {
                            try? await self.liveActivityService.endTimerActivity()
                            print("[GlobalTimerService] Live Activity ended after completion")
                        }
                    }
                }
                else {
                    print("[GlobalTimerService] Live Activity not started - Status: \(newTimerState.status), PreviousStatus: \(previousState?.status ?? .idle), IsActive: \(self.liveActivityService.isActivityActive)")
                }
            } catch {
                print("[GlobalTimerService] Live Activity error: \(error)")
                if let liveActivityError = error as? LiveActivityError {
                    print("[GlobalTimerService] LiveActivityError details: \(liveActivityError.errorDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func handleTimerCompletion() {
        cancelBackgroundNotification()
        endBackgroundTaskIfNeeded()
        
        print("[GlobalTimerService] Timer completed - will persist display until manual reset")
    }
    
    func setupAppLifecycleObservation() {
        backgroundTimerService.appLifecycleEvents
            .sink { [weak self] event in
                self?.handleAppLifecycleEvent(event)
            }
            .store(in: &cancellables)
        
        // LiveActivityの定期更新を削除
        // iOS 18ではLiveActivityの頻繁な更新が制限されているため、
        // タイマー開始/停止/完了時のみ更新するように変更
        
    }
    
    func handleAppLifecycleEvent(_ event: AppLifecycleEvent) {
        switch event {
        case .willResignActive:
            handleAppWillResignActive()
        case .didBecomeActive:
            handleAppDidBecomeActive()
        case .didEnterBackground:
            handleAppDidEnterBackground()
        case .willEnterForeground:
            handleAppWillEnterForeground()
        }
    }
    
    func handleAppWillResignActive() {
        guard isTimerActive else { return }
        scheduleBackgroundNotification()
        
        print("[GlobalTimerService] App will resign active - background notification scheduled")
    }
    
    func handleAppDidBecomeActive() {
        guard currentTimerState != nil else { return }
        syncWithCurrentTime()
        
        print("[GlobalTimerService] App did become active - timer synced")
    }
    
    func handleAppDidEnterBackground() {
        isAppInBackground = true
        
        guard isTimerActive else { return }
        
        // バックグラウンド移行時刻を保存
        persistenceService.saveBackgroundTransitionTime(Date())
        
        print("[GlobalTimerService] App entered background")
    }
    
    func handleAppWillEnterForeground() {
        isAppInBackground = false
        
        guard currentTimerState != nil else { return }
        
        // バックグラウンド移行時刻をクリア
        persistenceService.clearBackgroundTransitionTime()
        
        // タイマー状態を同期
        syncWithCurrentTime()
        
        print("[GlobalTimerService] App will enter foreground")
    }
    
    func restoreTimerStateIfNeeded() {
        guard let persistedTimer = persistenceService.loadTimerState() else { return }
        
        print("[GlobalTimerService] Restoring persisted timer state")
        
        // UseCaseにタイマー状態を復元
        intervalTimerUseCase.restoreTimerState(persistedTimer)
        
        // バックグラウンド移行時刻が保存されている場合は時間を同期
        if persistedTimer.status == .running {
            syncWithCurrentTime()
            
            // タイマーが実行中の場合、LiveActivityも開始する
            Task { [weak self] in
                guard let self = self else { return }
                if let timerState = self.currentTimerState {
                    print("[GlobalTimerService] Restoring Live Activity for running timer")
                    try? await self.liveActivityService.startTimerActivity(
                        timerState: timerState,
                        exerciseName: self.currentExerciseName
                    )
                }
            }
        }
    }
    
    func startBackgroundTaskIfNeeded() {
        guard backgroundTaskId == nil,
              backgroundTimerService.isBackgroundProcessingAvailable else { return }
        
        backgroundTaskId = backgroundTimerService.startBackgroundTask(
            identifier: "timer-background-task"
        ) { [weak self] in
            // バックグラウンドタスクの期限切れ時
            self?.handleBackgroundTaskExpiration()
        }
        
        print("[GlobalTimerService] Background task started: \(backgroundTaskId ?? "failed")")
        
        // BGProcessingTaskをスケジュール
        scheduleBackgroundProcessingTask()
    }
    
    func endBackgroundTaskIfNeeded() {
        guard let taskId = backgroundTaskId else { return }
        
        backgroundTimerService.endBackgroundTask(taskId: taskId)
        backgroundTaskId = nil
        
        print("[GlobalTimerService] Background task ended")
    }
    
    
    func scheduleBackgroundProcessingTask() {
        #if os(iOS)
        let request = BGProcessingTaskRequest(identifier: "com.bulktrack.timer-sync")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1分後
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[GlobalTimerService] Background processing task scheduled")
        } catch {
            print("[GlobalTimerService] Failed to schedule background processing task: \(error)")
        }
        #endif
    }
    
    func handleBackgroundTaskExpiration() {
        print("[GlobalTimerService] Background task expired - ending task")
        endBackgroundTaskIfNeeded()
        
        // タイマーが実行中の場合は通知をスケジュール
        if isTimerActive {
            scheduleBackgroundNotification()
        }
    }
    
    func shouldUpdateLiveActivity(newState: TimerState, previousState: TimerState?) -> Bool {
        // ステータスが変更された場合
        if newState.status != previousState?.status {
            return true
        }
        
        // 完了時
        if newState.isCompleted && previousState?.status == .running {
            return true
        }
        
        // それ以外（タイマー実行中の秒更新など）は更新しない
        return false
    }
}

// MARK: - Background App Refresh Status
public extension GlobalTimerService {
    var backgroundAppRefreshStatus: BackgroundAppRefreshStatus {
        backgroundTimerService.checkBackgroundAppRefreshStatus()
    }
    
    func requestBackgroundProcessingPermission() {
        backgroundTimerService.requestBackgroundProcessingPermission()
    }
}
