import Foundation
import Domain

/// タイマー設定管理サービスの実装
/// UserDefaultsを使用してタイマー設定を永続化
public final class TimerSettingsService: TimerSettingsServiceProtocol {
    
    // MARK: - Private Properties
    private let userDefaults: UserDefaults
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let defaultTimerDuration = "timer_default_duration"
    }
    
    // MARK: - Initialization
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - TimerSettingsServiceProtocol
    public var defaultTimerDuration: TimeInterval {
        let storedDuration = userDefaults.double(forKey: Keys.defaultTimerDuration)
        
        // 値が設定されていない場合はシステムデフォルトを返す
        if storedDuration == 0 {
            return TimerSettingsConstants.systemDefaultDuration
        }
        
        // 値が範囲外の場合はシステムデフォルトを返す
        if storedDuration < TimerSettingsConstants.minimumDuration || 
           storedDuration > TimerSettingsConstants.maximumDuration {
            return TimerSettingsConstants.systemDefaultDuration
        }
        
        return storedDuration
    }
    
    public func setDefaultTimerDuration(_ duration: TimeInterval) {
        // 範囲チェック
        let clampedDuration = max(
            TimerSettingsConstants.minimumDuration,
            min(TimerSettingsConstants.maximumDuration, duration)
        )
        
        userDefaults.set(clampedDuration, forKey: Keys.defaultTimerDuration)
        print("[TimerSettingsService] Default timer duration set to \(clampedDuration) seconds")
    }
    
    public func resetToDefaults() {
        userDefaults.removeObject(forKey: Keys.defaultTimerDuration)
        print("[TimerSettingsService] Timer settings reset to defaults")
    }
}