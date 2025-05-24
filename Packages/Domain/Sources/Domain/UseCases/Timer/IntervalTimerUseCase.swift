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
}

/// インターバルタイマー管理UseCase
public final class IntervalTimerUseCase: IntervalTimerUseCaseProtocol {
    @Published private var currentTimerState: TimerState
    private var timer: Timer?
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
        startTimerExecution()
    }
    
    public func pauseTimer() {
        guard currentTimerState.status == .running else { return }
        
        let newState = TimerState(
            duration: currentTimerState.duration,
            remainingTime: currentTimerState.remainingTime,
            status: .paused,
            exerciseId: currentTimerState.exerciseId,
            startedAt: currentTimerState.startedAt,
            pausedAt: Date(),
            shouldPersistAfterCompletion: currentTimerState.shouldPersistAfterCompletion
        )
        
        updateState(newState)
        stopTimerExecution()
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
        stopTimerExecution()
    }
    
    public func adjustTimer(minutes: Int) {
        let newDuration = max(60, currentTimerState.duration + TimeInterval(minutes * 60))
        let newRemainingTime: TimeInterval
        
        switch currentTimerState.status {
        case .idle:
            newRemainingTime = newDuration
        case .running, .paused:
            newRemainingTime = max(0, currentTimerState.remainingTime + TimeInterval(minutes * 60))
        case .completed:
            newRemainingTime = newDuration
        }
        
        let newState = TimerState(
            duration: newDuration,
            remainingTime: newRemainingTime,
            status: currentTimerState.status == .completed ? .idle : currentTimerState.status,
            exerciseId: currentTimerState.exerciseId,
            startedAt: currentTimerState.startedAt,
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
        stopTimerExecution()
    }
    
    public func syncWithCurrentTime() {
        guard let startedAt = currentTimerState.startedAt,
              currentTimerState.status == .running else { return }
        
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
            startTimerExecution()
        }
    }
}

// MARK: - Private Methods
private extension IntervalTimerUseCase {
    func updateState(_ newState: TimerState) {
        currentTimerState = newState
    }
    
    func startTimerExecution() {
        stopTimerExecution()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerTick()
        }
    }
    
    func stopTimerExecution() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateTimerTick() {
        guard currentTimerState.status == .running else { return }
        
        let newRemainingTime = max(0, currentTimerState.remainingTime - 1)
        
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
    
    func handleTimerCompletion() {
        stopTimerExecution()
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
    }
}
