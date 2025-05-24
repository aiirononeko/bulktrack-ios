import Foundation

/// タイマーの状態を表すEnum
public enum TimerStatus: Equatable {
    case idle       // 待機中
    case running    // 実行中
    case paused     // 一時停止
    case completed  // 完了
}

/// インターバルタイマーの状態を管理するエンティティ
public struct TimerState: Equatable {
    /// タイマーの設定時間（秒）
    public let duration: TimeInterval
    
    /// 残り時間（秒）
    public let remainingTime: TimeInterval
    
    /// タイマーの現在状態
    public let status: TimerStatus
    
    /// 関連する種目ID（Watch連携用）
    public let exerciseId: UUID?
    
    /// タイマー開始時刻（バックグラウンド復帰計算用）
    public let startedAt: Date?
    
    /// 一時停止時刻（バックグラウンド復帰計算用）
    public let pausedAt: Date?
    
    /// 完了後も表示を継続するかどうか
    public let shouldPersistAfterCompletion: Bool
    
    public init(
        duration: TimeInterval,
        remainingTime: TimeInterval,
        status: TimerStatus,
        exerciseId: UUID? = nil,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        shouldPersistAfterCompletion: Bool = false
    ) {
        self.duration = duration
        self.remainingTime = remainingTime
        self.status = status
        self.exerciseId = exerciseId
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.shouldPersistAfterCompletion = shouldPersistAfterCompletion
    }
}

// MARK: - Computed Properties
public extension TimerState {
    /// 経過時間
    var elapsedTime: TimeInterval {
        duration - remainingTime
    }
    
    /// 進捗率（0.0 〜 1.0）
    var progress: Double {
        guard duration > 0 else { return 0 }
        return elapsedTime / duration
    }
    
    /// 残り時間の表示用文字列（MM:SS形式）
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// タイマーが動作中かどうか
    var isActive: Bool {
        status == .running
    }
    
    /// タイマーが完了しているかどうか
    var isCompleted: Bool {
        status == .completed || remainingTime <= 0
    }
}

// MARK: - Factory Methods
public extension TimerState {
    /// デフォルトの3分タイマーを作成
    static func defaultTimer(exerciseId: UUID? = nil) -> TimerState {
        TimerState(
            duration: 180, // 3分
            remainingTime: 180,
            status: .idle,
            exerciseId: exerciseId
        )
    }
    
    /// 指定した時間のタイマーを作成
    static func timer(duration: TimeInterval, exerciseId: UUID? = nil) -> TimerState {
        TimerState(
            duration: duration,
            remainingTime: duration,
            status: .idle,
            exerciseId: exerciseId
        )
    }
}
