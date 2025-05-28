import Foundation

/// タイマー設定管理サービスのプロトコル
public protocol TimerSettingsServiceProtocol {
    /// デフォルトのタイマー時間を取得（秒）
    var defaultTimerDuration: TimeInterval { get }
    
    /// デフォルトのタイマー時間を設定（秒）
    /// - Parameter duration: 設定するタイマー時間（秒）
    func setDefaultTimerDuration(_ duration: TimeInterval)
    
    /// タイマー設定をリセット（デフォルト値に戻す）
    func resetToDefaults()
}

/// タイマー設定の定数
public enum TimerSettingsConstants {
    /// システムデフォルトのタイマー時間（3分 = 180秒）
    public static let systemDefaultDuration: TimeInterval = 180
    
    /// 最小タイマー時間（30秒）
    public static let minimumDuration: TimeInterval = 30
    
    /// 最大タイマー時間（10分 = 600秒）
    public static let maximumDuration: TimeInterval = 600
}