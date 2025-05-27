import Foundation
import Combine

/// グローバルタイマー管理のプロトコル
/// アプリ全体で単一のタイマーを管理し、画面遷移やアプリ切り替えでも状態を保持
@MainActor
public protocol GlobalTimerServiceProtocol {
    /// 現在のタイマー状態（nil = タイマーなし）
    var currentTimer: AnyPublisher<TimerState?, Never> { get }
    
    /// タイマーがアクティブかどうか
    var isTimerActive: Bool { get }
    
    /// バックグラウンドアプリ更新の状態
    var backgroundAppRefreshStatus: BackgroundAppRefreshStatus { get }
    
    /// グローバルタイマーを開始
    /// - Parameters:
    ///   - duration: タイマー時間（秒）
    ///   - exerciseId: 関連する種目ID
    func startGlobalTimer(duration: TimeInterval, exerciseId: UUID)
    
    /// グローバルタイマーを開始（種目名付き）
    /// - Parameters:
    ///   - duration: タイマー時間（秒）
    ///   - exerciseId: 関連する種目ID
    ///   - exerciseName: 種目名（LiveActivity表示用）
    func startGlobalTimer(duration: TimeInterval, exerciseId: UUID, exerciseName: String?)
    
    /// グローバルタイマーを一時停止
    func pauseGlobalTimer()
    
    /// グローバルタイマーを再開
    func resumeGlobalTimer()
    
    /// グローバルタイマーをリセット（完全停止）
    func resetGlobalTimer()
    
    /// グローバルタイマーを完全にクリア（UI非表示にする）
    func clearGlobalTimer()
    
    /// タイマー時間を調整（分単位）
    /// - Parameter minutes: 調整する分数（正数で増加、負数で減少）
    func adjustGlobalTimer(minutes: Int)
    
    /// バックグラウンドから復帰時の時間同期
    func syncWithCurrentTime()
    
    /// バックグラウンド通知をスケジュール
    func scheduleBackgroundNotification()
    
    /// スケジュールされた通知をキャンセル
    func cancelBackgroundNotification()
    
    /// バックグラウンド処理の権限を要求（設定画面を開く）
    func requestBackgroundProcessingPermission()
}
