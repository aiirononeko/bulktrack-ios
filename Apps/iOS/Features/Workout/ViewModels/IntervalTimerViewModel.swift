import SwiftUI
import Foundation
import Combine
import Domain

#if os(iOS)
import UIKit
#endif

/// タイマーのUI状態
enum TimerUIState: Equatable {
    case collapsed(isRunning: Bool)  // アイコンのみ表示
    case expanded                    // フルパネル表示
    
    var isExpanded: Bool {
        if case .expanded = self {
            return true
        }
        return false
    }
    
    var isCollapsedAndRunning: Bool {
        if case .collapsed(let isRunning) = self {
            return isRunning
        }
        return false
    }
}

@MainActor
final class IntervalTimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var timerState: TimerState = .defaultTimer()
    @Published var uiState: TimerUIState = .collapsed(isRunning: false)
    @Published var showTimerControls = false
    
    // MARK: - Private Properties
    private let intervalTimerUseCase: IntervalTimerUseCaseProtocol
    private let notificationUseCase: TimerNotificationUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        intervalTimerUseCase: IntervalTimerUseCaseProtocol,
        notificationUseCase: TimerNotificationUseCaseProtocol,
        exerciseId: UUID? = nil
    ) {
        self.intervalTimerUseCase = intervalTimerUseCase
        self.notificationUseCase = notificationUseCase
        
        setupTimerObservation()
        setupBackgroundHandling()
        
        // 種目IDが指定されている場合はタイマーに設定
        if let exerciseId = exerciseId {
            intervalTimerUseCase.setTimer(duration: 180, exerciseId: exerciseId)
        }
        
        requestNotificationPermissionIfNeeded()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Public Methods
extension IntervalTimerViewModel {
    /// タイマーボタンタップ時の処理
    func onTimerButtonTapped() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch uiState {
            case .collapsed:
                uiState = .expanded
            case .expanded:
                uiState = .collapsed(isRunning: timerState.isActive)
            }
        }
    }
    
    /// タイマー開始/停止の切り替え
    func toggleTimer() {
        switch timerState.status {
        case .idle, .paused, .completed:
            intervalTimerUseCase.startTimer()
            scheduleBackgroundNotificationIfNeeded()
        case .running:
            intervalTimerUseCase.pauseTimer()
            notificationUseCase.cancelScheduledNotifications()
        }
    }
    
    /// タイマーリセット
    func resetTimer() {
        intervalTimerUseCase.resetTimer()
        notificationUseCase.cancelScheduledNotifications()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            uiState = .collapsed(isRunning: false)
        }
    }
    
    /// タイマー時間調整
    func adjustTimer(minutes: Int) {
        intervalTimerUseCase.adjustTimer(minutes: minutes)
        
        // タイマー実行中の場合は通知を再スケジュール
        if timerState.isActive {
            scheduleBackgroundNotificationIfNeeded()
        }
    }
    
    /// タイマー設定変更
    func setTimerDuration(_ duration: TimeInterval) {
        intervalTimerUseCase.setTimer(duration: duration, exerciseId: timerState.exerciseId)
    }
}

// MARK: - Private Methods
private extension IntervalTimerViewModel {
    func setupTimerObservation() {
        intervalTimerUseCase.timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTimerState in
                self?.handleTimerStateUpdate(newTimerState)
            }
            .store(in: &cancellables)
    }
    
    func handleTimerStateUpdate(_ newTimerState: TimerState) {
        let previousState = timerState
        timerState = newTimerState
        
        // UI状態の更新
        updateUIState(previousState: previousState, newState: newTimerState)
        
        // タイマー完了時の処理
        if newTimerState.isCompleted && previousState.status == .running {
            handleTimerCompletion()
        }
    }
    
    func updateUIState(previousState: TimerState, newState: TimerState) {
        // 展開状態でない場合のみ、collapse状態を更新
        if case .collapsed = uiState {
            uiState = .collapsed(isRunning: newState.isActive)
        }
    }
    
    func handleTimerCompletion() {
        // 完了後は自動的にコンパクト表示に戻る
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.uiState = .collapsed(isRunning: false)
            }
        }
    }
    
    func setupBackgroundHandling() {
        #if os(iOS)
        // アプリのライフサイクル監視
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
        #else
        // watchOSでは現在のところアプリライフサイクル監視は不要
        // 必要に応じてwatchOS固有の実装を追加
        print("[IntervalTimerViewModel] watchOS: App lifecycle observation not implemented")
        #endif
    }
    
    func handleAppWillResignActive() {
        // バックグラウンドに入る時、実行中なら通知をスケジュール
        scheduleBackgroundNotificationIfNeeded()
    }
    
    func handleAppDidBecomeActive() {
        // フォアグラウンドに戻った時、時間を同期
        intervalTimerUseCase.syncWithCurrentTime()
        notificationUseCase.cancelScheduledNotifications()
    }
    
    func scheduleBackgroundNotificationIfNeeded() {
        guard timerState.isActive && timerState.remainingTime > 0 else { return }
        notificationUseCase.scheduleBackgroundNotification(remainingTime: timerState.remainingTime)
    }
    
    func requestNotificationPermissionIfNeeded() {
        Task {
            await notificationUseCase.requestNotificationPermission()
        }
    }
}

// MARK: - Computed Properties
extension IntervalTimerViewModel {
    /// 表示用の残り時間
    var displayTime: String {
        timerState.formattedRemainingTime
    }
    
    /// 進捗率
    var progress: Double {
        timerState.progress
    }
    
    /// 再生/一時停止ボタンのアイコン
    var playPauseIcon: String {
        switch timerState.status {
        case .idle, .paused, .completed:
            return "play.fill"
        case .running:
            return "pause.fill"
        }
    }
    
    /// タイマーアイコンボタンの表示内容
    var timerButtonContent: String {
        switch uiState {
        case .collapsed(let isRunning):
            return isRunning ? timerState.formattedRemainingTime : "timer"
        case .expanded:
            return "timer"
        }
    }
    
    /// タイマーが完了状態かどうか
    var isCompleted: Bool {
        timerState.isCompleted
    }
}
