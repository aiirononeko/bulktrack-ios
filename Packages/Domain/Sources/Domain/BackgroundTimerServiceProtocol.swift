import Foundation
import Combine

/// バックグラウンドタイマー管理のプロトコル
/// アプリがバックグラウンドに移行してもタイマーの動作を継続するための抽象インターフェース
@MainActor
public protocol BackgroundTimerServiceProtocol {
    /// バックグラウンド処理が利用可能かどうか
    var isBackgroundProcessingAvailable: Bool { get }
    
    /// バックグラウンドタスクを開始
    /// - Parameters:
    ///   - identifier: タスクの識別子
    ///   - expirationHandler: タスクの期限切れ時に実行されるハンドラ
    /// - Returns: バックグラウンドタスクのID
    func startBackgroundTask(
        identifier: String,
        expirationHandler: @escaping () -> Void
    ) -> String?
    
    /// バックグラウンドタスクを終了
    /// - Parameter taskId: 終了するタスクのID
    func endBackgroundTask(taskId: String)
    
    /// アプリライフサイクルの変更通知を監視
    var appLifecycleEvents: AnyPublisher<AppLifecycleEvent, Never> { get }
    
    /// バックグラウンド App Refresh の許可状態を確認
    func checkBackgroundAppRefreshStatus() -> BackgroundAppRefreshStatus
    
    /// バックグラウンド処理の許可をリクエスト（設定画面へ誘導）
    func requestBackgroundProcessingPermission()
}

/// アプリライフサイクルイベント
public enum AppLifecycleEvent: Equatable {
    case willResignActive
    case didBecomeActive
    case didEnterBackground
    case willEnterForeground
}

/// バックグラウンド App Refresh の状態
public enum BackgroundAppRefreshStatus: Equatable {
    case available
    case denied
    case restricted
}
