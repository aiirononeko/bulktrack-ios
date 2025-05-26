import Foundation
import Combine

/// インターバルタイマー管理のプロトコル
public protocol IntervalTimerUseCaseProtocol {
    /// タイマーの現在状態
    var timerState: AnyPublisher<TimerState, Never> { get }
    
    /// タイマーを開始
    func startTimer()
    
    /// タイマーを一時停止
    func pauseTimer()
    
    /// タイマーをリセット
    func resetTimer()
    
    /// タイマー時間を調整（分単位）
    func adjustTimer(minutes: Int)
    
    /// 新しいタイマーを設定
    func setTimer(duration: TimeInterval, exerciseId: UUID?)
    
    /// バックグラウンドから復帰時の時間同期
    func syncWithCurrentTime()
    
    /// 永続化されたタイマー状態を復元
    func restoreTimerState(_ timerState: TimerState)
}

/// インターバルタイマー管理UseCase
/// Date-basedアプローチでバックグラウンド動作に対応
public final class IntervalTimerUseCase: IntervalTimerUseCaseProtocol {
    @Published private var currentTimerState: TimerState
    private var displayUpdateTimer: Timer?
    private let notificationUseCase: TimerNotificationUseCaseProtocol
    
    public var timerState: AnyPublisher<TimerState, Never> {
        $currentTimerState.eraseToAnyPublisher()
    }
    
    public init(
        initialState: TimerState = .defaultTimer(),
        notificationUseCase: TimerNotificationUseCaseProtocol
    ) {
        self.currentTimerState = initialState
        self.notificationUseCase = notificationUseCase
    }
    
    public func startTimer() {
        guard currentTimerState.status != .running else { return }
        
        let newState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: currentTimerState.remainingTime,
            status: .running,
            exerciseId: currentTimerState.exerciseId,
            startedAt: Date(),
            pausedAt: nil,
            shouldPersistAfterCompletion: false
        )
        
        updateState(newState)
        startDisplayUpdates()
    }
    
    public func pauseTimer() {
        guard currentTimerState.status == .running else { return }
        
        // 現在の残り時間を正確に計算
        let calculatedRemainingTime = calculateCurrentRemainingTime()
        
        let newState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: calculatedRemainingTime,
            status: .paused,
            exerciseId: currentTimerState.exerciseId,
            startedAt: currentTimerState.startedAt,
            pausedAt: Date(),
            shouldPersistAfterCompletion: currentTimerState.shouldPersistAfterCompletion
        )
        
        updateState(newState)
        stopDisplayUpdates()
    }
    
    public func resetTimer() {
        let newState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: currentTimerState.duration,
            status: .idle,
            exerciseId: currentTimerState.exerciseId,
            startedAt: nil,
            pausedAt: nil,
            shouldPersistAfterCompletion: false
        )
        
        updateState(newState)
        stopDisplayUpdates()
    }
    
    public func adjustTimer(minutes: Int) {
        let adjustment = TimeInterval(minutes * 60)
        let newDuration = max(60, currentTimerState.duration + adjustment)
        
        let newRemainingTime: TimeInterval
        switch currentTimerState.status {
        case .idle:
            newRemainingTime = newDuration
        case .running:
            // 実行中は現在の残り時間に調整を加える
            let currentRemaining = calculateCurrentRemainingTime()
            newRemainingTime = max(0, currentRemaining + adjustment)
        case .paused:
            newRemainingTime = max(0, currentTimerState.remainingTime + adjustment)
        case .completed:
            newRemainingTime = newDuration
        }
        
        let newState = TimerState(
            duration: newDuration,
            remainingTime: newRemainingTime,
            status: currentTimerState.status == .completed ? .idle : currentTimerState.status,
            exerciseId: currentTimerState.exerciseId,
            startedAt: currentTimerState.status == .running ? Date() : currentTimerState.startedAt,
            pausedAt: currentTimerState.pausedAt,
            shouldPersistAfterCompletion: false
        )
        
        updateState(newState)
    }
    
    public func setTimer(duration: TimeInterval, exerciseId: UUID?) {
        let newState = TimerState(
            duration: duration,
            remainingTime: duration,
            status: .idle,
            exerciseId: exerciseId,
            startedAt: nil,
            pausedAt: nil,
            shouldPersistAfterCompletion: false
        )
        
        updateState(newState)
        stopDisplayUpdates()
    }
    
    public func syncWithCurrentTime() {
        guard currentTimerState.status == .running,
              let startedAt = currentTimerState.startedAt else {
            // running状態でない場合はタイマーの再開始のみ行う
            if currentTimerState.status == .running {
                startDisplayUpdates()
            }
            return
        }
        
        let elapsed = Date().timeIntervalSince(startedAt)
        let newRemainingTime = max(0, currentTimerState.duration - elapsed)
        
        let newState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: newRemainingTime,
            status: newRemainingTime <= 0 ? .completed : .running,
            exerciseId: currentTimerState.exerciseId,
            startedAt: startedAt,
            pausedAt: nil,
            shouldPersistAfterCompletion: newRemainingTime <= 0 ? true : false
        )
        
        updateState(newState)
        
        if newState.isCompleted {
            handleTimerCompletion()
        } else {
            startDisplayUpdates()
        }
    }
    
    public func restoreTimerState(_ timerState: TimerState) {
        updateState(timerState)
        
        // 復元されたタイマーが実行中の場合は時間同期を行う
        if timerState.status == .running {
            syncWithCurrentTime()
        }
        
        print("[IntervalTimerUseCase] Timer state restored: \(timerState.status), remaining: \(timerState.formattedRemainingTime)")
    }
}

// MARK: - Private Methods
private extension IntervalTimerUseCase {
    func updateState(_ newState: TimerState) {
        currentTimerState = newState
    }
    
    func startDisplayUpdates() {
        stopDisplayUpdates()
        
        // UIの更新のためのタイマー（1秒間隔）
        displayUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }
    
    func stopDisplayUpdates() {
        displayUpdateTimer?.invalidate()
        displayUpdateTimer = nil
    }
    
    func updateDisplay() {
        guard currentTimerState.status == .running else { return }
        
        let newRemainingTime = calculateCurrentRemainingTime()
        
        let newState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: newRemainingTime,
            status: newRemainingTime <= 0 ? .completed : .running,
            exerciseId: currentTimerState.exerciseId,
            startedAt: currentTimerState.startedAt,
            pausedAt: nil,
            shouldPersistAfterCompletion: newRemainingTime <= 0 ? true : false
        )
        
        updateState(newState)
        
        if newState.isCompleted {
            handleTimerCompletion()
        }
    }
    
    func calculateCurrentRemainingTime() -> TimeInterval {
        guard let startedAt = currentTimerState.startedAt,
              currentTimerState.status == .running else {
            return currentTimerState.remainingTime
        }
        
        let elapsed = Date().timeIntervalSince(startedAt)
        return max(0, currentTimerState.duration - elapsed)
    }
    
    func handleTimerCompletion() {
        stopDisplayUpdates()
        notificationUseCase.notifyTimerCompletion()
        
        // 完了後は表示を継続するためのフラグを設定
        let completedState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: 0,
            status: .completed,
            exerciseId: currentTimerState.exerciseId,
            startedAt: currentTimerState.startedAt,
            pausedAt: nil,
            shouldPersistAfterCompletion: true
        )
        
        updateState(completedState)
        
        print("[IntervalTimerUseCase] Timer completed")
    }
}
