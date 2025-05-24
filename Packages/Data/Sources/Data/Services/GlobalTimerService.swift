import Foundation
@preconcurrency import Combine
import Domain

#if os(iOS)
import UIKit
#endif

/// グローバルタイマー管理サービスの実装
/// アプリ全体で単一のタイマーを管理し、画面遷移やアプリ切り替えでも状態を保持
@MainActor
public final class GlobalTimerService: GlobalTimerServiceProtocol {
    // MARK: - Published Properties
    @Published private var currentTimerState: TimerState?
    
    // MARK: - Private Properties
    private let intervalTimerUseCase: IntervalTimerUseCaseProtocol
    private let notificationUseCase: TimerNotificationUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
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
        notificationUseCase: TimerNotificationUseCaseProtocol
    ) {
        self.intervalTimerUseCase = intervalTimerUseCase
        self.notificationUseCase = notificationUseCase
        
        setupTimerObservation()
        setupAppLifecycleObservation()
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
        
        print("[GlobalTimerService] Timer started - Duration: \(duration)s, ExerciseID: \(exerciseId)")
    }
    
    func pauseGlobalTimer() {
        guard currentTimerState?.status == .running else { return }
        intervalTimerUseCase.pauseTimer()
        cancelBackgroundNotification()
        
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
        
        scheduleBackgroundNotification()
        
        print("[GlobalTimerService] Timer resumed")
    }
    
    func resetGlobalTimer() {
        intervalTimerUseCase.resetTimer()
        cancelBackgroundNotification()
        
        print("[GlobalTimerService] Timer reset")
    }
    
    func clearGlobalTimer() {
        intervalTimerUseCase.resetTimer()
        cancelBackgroundNotification()
        currentTimerState = nil
        
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
        
        // 完了状態でない場合のみ通知をキャンセル
        if let timer = currentTimerState, !timer.shouldPersistAfterCompletion {
            cancelBackgroundNotification()
        }
        
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
        
        // タイマー完了時の処理
        if newTimerState.isCompleted && previousState?.status == .running {
            handleTimerCompletion()
        }
        
        // タイマー開始時の処理
        if newTimerState.status == .running && previousState?.status != .running {
            scheduleBackgroundNotification()
        }
        
        print("[GlobalTimerService] Timer state updated: \(newTimerState.status), remaining: \(newTimerState.formattedRemainingTime), shouldPersist: \(newTimerState.shouldPersistAfterCompletion)")
    }
    
    func handleTimerCompletion() {
        cancelBackgroundNotification()
        
        // 完了後は表示を継続する
        // shouldPersistAfterCompletionがtrueの場合、ユーザーが明示的にリセットするまで表示し続ける
        
        print("[GlobalTimerService] Timer completed - will persist display until manual reset")
    }
    
    func setupAppLifecycleObservation() {
        #if os(iOS)
        // アプリがバックグラウンドに移行する時
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        // アプリがフォアグラウンドに復帰する時
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
        #else
        // watchOSでは現在のところアプリライフサイクル監視は不要
        // 必要に応じてwatchOS固有の実装を追加
        print("[GlobalTimerService] watchOS: App lifecycle observation not implemented")
        #endif
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
}
