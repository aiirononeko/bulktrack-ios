import Foundation

/// Live Activity（Dynamic Island）管理のプロトコル
@MainActor
public protocol LiveActivityServiceProtocol {
    /// 現在のLive Activityが実行中かどうか
    var isActivityActive: Bool { get }
    
    /// タイマーのLive Activityを開始
    /// - Parameters:
    ///   - timerState: タイマーの初期状態
    ///   - exerciseName: 種目名（表示用）
    func startTimerActivity(timerState: TimerState, exerciseName: String?) async throws
    
    /// タイマーのLive Activityを更新
    /// - Parameter timerState: 更新されたタイマー状態
    func updateTimerActivity(timerState: TimerState) async throws
    
    /// Live Activityを終了
    func endTimerActivity() async
    
    /// 全てのLive Activityを強制終了
    func endAllActivities() async
}

// MARK: - Live Activity Errors
public enum LiveActivityError: LocalizedError {
    case notAvailable
    case notAuthorized
    case noActiveActivity
    case failedToStart(Error)
    case failedToUpdate(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Live ActivitiesはiOS 16.1以降でのみ利用可能です。"
        case .notAuthorized:
            return "Live Activitiesが許可されていません。設定から有効にしてください。"
        case .noActiveActivity:
            return "アクティブなLive Activityがありません。"
        case .failedToStart(let error):
            return "Live Activityの開始に失敗しました: \(error.localizedDescription)"
        case .failedToUpdate(let error):
            return "Live Activityの更新に失敗しました: \(error.localizedDescription)"
        }
    }
}
