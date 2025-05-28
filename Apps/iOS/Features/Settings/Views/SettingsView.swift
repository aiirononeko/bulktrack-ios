import SwiftUI
import Domain

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showTimerSettings = false
    
    init(timerSettingsService: TimerSettingsServiceProtocol, deviceIdentificationUseCase: DeviceIdentificationUseCase) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(timerSettingsService: timerSettingsService, deviceIdentificationUseCase: deviceIdentificationUseCase))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("タイマー設定") {
                    HStack {
                        Label("デフォルトタイマー時間", systemImage: "timer")
                        Spacer()
                        Text(viewModel.formattedTimerDuration)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showTimerSettings = true
                    }
                }
                
                Section {
                    Button("設定をリセット") {
                        viewModel.resetSettings()
                    }
                    .foregroundColor(.red)
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("ID: \(viewModel.deviceId)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("設定")
        }
        .sheet(isPresented: $showTimerSettings) {
            TimerSettingsSheet { duration in
                viewModel.setTimerDuration(duration)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            timerSettingsService: PreviewTimerSettingsService(),
            deviceIdentificationUseCase: DeviceIdentificationUseCase(
                deviceIdentifierService: PreviewDeviceIdentifierService()
            )
        )
    }
}

// MARK: - Preview Helper
private class PreviewTimerSettingsService: TimerSettingsServiceProtocol {
    var defaultTimerDuration: TimeInterval = 180
    
    func setDefaultTimerDuration(_ duration: TimeInterval) {
        defaultTimerDuration = duration
    }
    
    func resetToDefaults() {
        defaultTimerDuration = 180
    }
}

private class PreviewDeviceIdentifierService: DeviceIdentifierServiceProtocol {
    func getDeviceIdentifier() -> String {
        return "PREVIEW-DEVICE-ID"
    }
}
