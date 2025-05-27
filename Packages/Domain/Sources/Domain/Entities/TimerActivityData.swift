import Foundation

#if os(iOS)
import ActivityKit
#endif

/// Timer Live Activity用のデータ構造
/// Widget ExtensionとLiveActivityServiceで共有される
public struct TimerActivityData {
    /// タイマーの残り時間（秒）
    public let remainingTime: TimeInterval
    /// タイマーの全体時間（秒）
    public let duration: TimeInterval
    /// タイマーの状態
    public let status: TimerActivityStatus
    /// 種目名（オプション）
    public let exerciseName: String?
    
    public init(remainingTime: TimeInterval, duration: TimeInterval, status: TimerActivityStatus, exerciseName: String? = nil) {
        self.remainingTime = remainingTime
        self.duration = duration
        self.status = status
        self.exerciseName = exerciseName
    }
}

/// タイマーの状態（Activity用）
public enum TimerActivityStatus: String, Codable, CaseIterable {
    case idle = "idle"
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    
    public var displayName: String {
        switch self {
        case .idle:
            return "待機中"
        case .running:
            return "実行中"
        case .paused:
            return "一時停止"
        case .completed:
            return "完了"
        }
    }
    
    public var isActive: Bool {
        return self == .running
    }
    
    public var systemImageName: String {
        switch self {
        case .idle:
            return "timer"
        case .running:
            return "play.fill"
        case .paused:
            return "pause.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .idle:
            return "gray"
        case .running:
            return "green"
        case .paused:
            return "orange"
        case .completed:
            return "blue"
        }
    }
}

// MARK: - TimerState Extension for Live Activity
public extension TimerState {
    /// Live Activity用のTimerActivityDataに変換
    func toActivityData(exerciseName: String? = nil) -> TimerActivityData {
        let status: TimerActivityStatus
        switch self.status {
        case .idle:
            status = .idle
        case .running:
            status = .running
        case .paused:
            status = .paused
        case .completed:
            status = .completed
        }
        
        return TimerActivityData(
            remainingTime: remainingTime,
            duration: duration,
            status: status,
            exerciseName: exerciseName
        )
    }
}

// MARK: - Helper Extensions
public extension TimerActivityData {
    /// 残り時間をフォーマットされた文字列で取得
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 進捗率を取得（0.0〜1.0）
    var progress: Double {
        guard duration > 0 else { return 0.0 }
        let elapsed = duration - remainingTime
        return min(max(elapsed / duration, 0.0), 1.0)
    }
    
    /// 表示用の種目名を取得
    var displayExerciseName: String {
        return exerciseName ?? "ワークアウト"
    }
}

// MARK: - ActivityKit Types
#if os(iOS)

/// Timer Live Activity用の属性定義
public struct TimerActivityAttributes: ActivityAttributes {
    public typealias ContentState = TimerActivityContentState
    
    /// タイマーID（一意識別子）
    public let timerId: String
    
    public init(timerId: String) {
        self.timerId = timerId
    }
}

/// Timer Live Activity用のContentState
/// DomainのTimerActivityDataをActivityKitのContentStateに適合させる
public struct TimerActivityContentState: Codable, Hashable {
    /// タイマーの残り時間（秒）
    public let remainingTime: TimeInterval
    /// タイマーの全体時間（秒）
    public let duration: TimeInterval
    /// タイマーの状態
    public let status: TimerActivityStatus
    /// 種目名（オプション）
    public let exerciseName: String?
    
    public init(remainingTime: TimeInterval, duration: TimeInterval, status: TimerActivityStatus, exerciseName: String? = nil) {
        self.remainingTime = remainingTime
        self.duration = duration
        self.status = status
        self.exerciseName = exerciseName
    }
    
    /// DomainのTimerActivityDataから変換
    public init(from activityData: TimerActivityData) {
        self.remainingTime = activityData.remainingTime
        self.duration = activityData.duration
        self.status = activityData.status
        self.exerciseName = activityData.exerciseName
    }
}

// MARK: - Helper Extensions for Widget Views
public extension TimerActivityContentState {
    /// 残り時間をフォーマットされた文字列で取得
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 進捗率を取得（0.0〜1.0）
    var progress: Double {
        guard duration > 0 else { return 0.0 }
        let elapsed = duration - remainingTime
        return min(max(elapsed / duration, 0.0), 1.0)
    }
    
    /// 表示用の種目名を取得
    var displayExerciseName: String {
        return exerciseName ?? "ワークアウト"
    }
}

#endif
