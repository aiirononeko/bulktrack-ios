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
    func endTimerActivity() async throws
    
    /// 全てのLive Activityを強制終了
    func endAllActivities() async throws
}
