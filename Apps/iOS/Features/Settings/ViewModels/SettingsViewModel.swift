import SwiftUI
import Domain

/// 設定画面のViewModel
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTimerDuration: TimeInterval
    
    // MARK: - Private Properties
    private let timerSettingsService: TimerSettingsServiceProtocol
    
    // MARK: - Computed Properties
    var formattedTimerDuration: String {
        let minutes = Int(currentTimerDuration) / 60
        let seconds = Int(currentTimerDuration) % 60
        
        if seconds == 0 {
            return "\(minutes)分"
        } else {
            return "\(minutes)分\(seconds)秒"
        }
    }
    
    // MARK: - Initialization
    init(timerSettingsService: TimerSettingsServiceProtocol) {
        self.timerSettingsService = timerSettingsService
        self.currentTimerDuration = timerSettingsService.defaultTimerDuration
    }
    
    // MARK: - Public Methods
    func setTimerDuration(_ seconds: Int) {
        let duration = TimeInterval(seconds)
        timerSettingsService.setDefaultTimerDuration(duration)
        currentTimerDuration = duration
        print("[SettingsViewModel] Timer duration updated to \(duration) seconds")
    }
    
    func resetSettings() {
        timerSettingsService.resetToDefaults()
        currentTimerDuration = timerSettingsService.defaultTimerDuration
        print("[SettingsViewModel] Settings reset to defaults")
    }
}