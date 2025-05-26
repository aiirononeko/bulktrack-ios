import Foundation

/// タイマー状態の永続化管理プロトコル
/// アプリの終了・再起動時にタイマー状態を保存・復元するための抽象インターフェース
public protocol TimerPersistenceServiceProtocol {
    /// タイマー状態を永続化
    /// - Parameter timerState: 保存するタイマー状態
    func saveTimerState(_ timerState: TimerState)
    
    /// 永続化されたタイマー状態を復元
    /// - Returns: 復元されたタイマー状態（なければnil）
    func loadTimerState() -> TimerState?
    
    /// 永続化されたタイマー状態をクリア
    func clearTimerState()
    
    /// タイマー状態が永続化されているかどうか
    var hasPersistedTimerState: Bool { get }
    
    /// バックグラウンド移行時刻を保存
    /// - Parameter date: バックグラウンド移行時刻
    func saveBackgroundTransitionTime(_ date: Date)
    
    /// バックグラウンド移行時刻を取得
    /// - Returns: バックグラウンド移行時刻（なければnil）
    func loadBackgroundTransitionTime() -> Date?
    
    /// バックグラウンド移行時刻をクリア
    func clearBackgroundTransitionTime()
}

/// 永続化されたタイマーデータ
public struct PersistedTimerData: Codable {
    public let duration: TimeInterval
    public let remainingTime: TimeInterval
    public let status: TimerStatus
    public let exerciseId: UUID?
    public let startedAt: Date?
    public let pausedAt: Date?
    public let shouldPersistAfterCompletion: Bool
    public let persistedAt: Date
    
    public init(
        duration: TimeInterval,
        remainingTime: TimeInterval,
        status: TimerStatus,
        exerciseId: UUID?,
        startedAt: Date?,
        pausedAt: Date?,
        shouldPersistAfterCompletion: Bool,
        persistedAt: Date = Date()
    ) {
        self.duration = duration
        self.remainingTime = remainingTime
        self.status = status
        self.exerciseId = exerciseId
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.shouldPersistAfterCompletion = shouldPersistAfterCompletion
        self.persistedAt = persistedAt
    }
    
    /// TimerStateから PersistedTimerData を作成
    public init(from timerState: TimerState) {
        self.duration = timerState.duration
        self.remainingTime = timerState.remainingTime
        self.status = timerState.status
        self.exerciseId = timerState.exerciseId
        self.startedAt = timerState.startedAt
        self.pausedAt = timerState.pausedAt
        self.shouldPersistAfterCompletion = timerState.shouldPersistAfterCompletion
        self.persistedAt = Date()
    }
    
    /// PersistedTimerData から TimerState を復元
    public func toTimerState() -> TimerState {
        TimerState(
            duration: duration,
            remainingTime: remainingTime,
            status: status,
            exerciseId: exerciseId,
            startedAt: startedAt,
            pausedAt: pausedAt,
            shouldPersistAfterCompletion: shouldPersistAfterCompletion
        )
    }
}

// MARK: - TimerStatus Codable Support
extension TimerStatus: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "idle":
            self = .idle
        case "running":
            self = .running
        case "paused":
            self = .paused
        case "completed":
            self = .completed
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown TimerStatus: \(rawValue)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .idle:
            try container.encode("idle")
        case .running:
            try container.encode("running")
        case .paused:
            try container.encode("paused")
        case .completed:
            try container.encode("completed")
        }
    }
}
