import SwiftUI

/// タイマー設定シート
struct TimerSettingsSheet: View {
    let onDurationSet: (Int) -> Void
    
    @State private var selectedMinutes = 3
    @State private var selectedSeconds = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private let minutes = Array(0...10)
    private let seconds = Array(0...59)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("インターバル時間を設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // ピッカー
                HStack(spacing: 12) {
                    Picker("分", selection: $selectedMinutes) {
                        ForEach(minutes, id: \.self) { minute in
                            Text("\(minute)")
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 150)
                    
                    Text("分")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Picker("秒", selection: $selectedSeconds) {
                        ForEach(seconds, id: \.self) { second in
                            Text(String(format: "%02d", second))
                                .tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 150)
                    
                    Text("秒")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                // プリセットボタン
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    PresetButton(minutes: 1, seconds: 0, selectedMinutes: $selectedMinutes, selectedSeconds: $selectedSeconds, colorScheme: colorScheme)
                    PresetButton(minutes: 1, seconds: 30, selectedMinutes: $selectedMinutes, selectedSeconds: $selectedSeconds, colorScheme: colorScheme)
                    PresetButton(minutes: 2, seconds: 0, selectedMinutes: $selectedMinutes, selectedSeconds: $selectedSeconds, colorScheme: colorScheme)
                    PresetButton(minutes: 3, seconds: 0, selectedMinutes: $selectedMinutes, selectedSeconds: $selectedSeconds, colorScheme: colorScheme)
                    PresetButton(minutes: 4, seconds: 0, selectedMinutes: $selectedMinutes, selectedSeconds: $selectedSeconds, colorScheme: colorScheme)
                    PresetButton(minutes: 5, seconds: 0, selectedMinutes: $selectedMinutes, selectedSeconds: $selectedSeconds, colorScheme: colorScheme)
                }
                
                Spacer()
                
                // 設定ボタン
                Button {
                    let totalSeconds = selectedMinutes * 60 + selectedSeconds
                    onDurationSet(totalSeconds)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("タイマーを設定")
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(colorScheme == .dark ? .white : .black)
                    .cornerRadius(12)
                }
                .disabled(selectedMinutes == 0 && selectedSeconds == 0)
                .opacity((selectedMinutes == 0 && selectedSeconds == 0) ? 0.6 : 1.0)
            }
            .padding()
            .navigationTitle("タイマー設定")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("キャンセル") {
                    dismiss()
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            )
        }
    }
}

/// プリセット時間ボタン
private struct PresetButton: View {
    let minutes: Int
    let seconds: Int
    @Binding var selectedMinutes: Int
    @Binding var selectedSeconds: Int
    let colorScheme: ColorScheme
    
    private var isSelected: Bool {
        selectedMinutes == minutes && selectedSeconds == seconds
    }
    
    var body: some View {
        Button {
            selectedMinutes = minutes
            selectedSeconds = seconds
        } label: {
            VStack(spacing: 4) {
                Text("\(minutes):\(String(format: "%02d", seconds))")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : .primary)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (colorScheme == .dark ? .white : .black) : Color(.systemGray5))
            )
        }
    }
}

// MARK: - Preview
struct TimerSettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerSettingsSheet { duration in
                print("Selected duration: \(duration) seconds")
            }
            .preferredColorScheme(.light)
            
            TimerSettingsSheet { duration in
                print("Selected duration: \(duration) seconds")
            }
            .preferredColorScheme(.dark)
        }
    }
}