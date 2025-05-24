import SwiftUI
import Domain

/// シンプルなタイマーボタン（操作パネルは外部管理）
/// セット登録ボタンの横に配置される通常のボタン
struct TimerButton: View {
    let timerState: TimerState
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: timerIconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(mainButtonBackgroundColor)
            )
        }
    }
}

// MARK: - Computed Properties
private extension TimerButton {
    var mainButtonBackgroundColor: Color {
        switch timerState.status {
        case .running:
            return .yellow
        case .completed:
            return .orange
        case .idle, .paused:
            return .black
        }
    }
    
    var timerIconName: String {
        switch timerState.status {
        case .completed:
            return "checkmark.circle.fill"
        default:
            return "timer"
        }
    }
}

// MARK: - Timer Control Panel Component
struct TimerControlPanel: View {
    let timerState: TimerState
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onAdjustTimer: (Int) -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 時間調整ボタン（-1分）
            adjustButton(minutes: -1, icon: "minus", isDisabled: shouldDisableAdjustButtons || timerState.duration <= 60)
            
            // 再生/一時停止ボタン
            Button(action: onToggleTimer) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(playPauseBackgroundColor)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
            }
            .scaleEffect(timerState.isActive ? 1.0 : 0.95)
            .animation(.spring(response: 0.3), value: timerState.isActive)
            
            // リセットボタン
            Button(action: onResetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.gray.opacity(0.8))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
            }
            .disabled(shouldDisableResetButton)
            
            // 時間調整ボタン（+1分）
            adjustButton(minutes: 1, icon: "plus", isDisabled: shouldDisableAdjustButtons)
            
            Spacer()
            
            // 閉じるボタン
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.black.opacity(0.6))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        )
    }
    
    func adjustButton(minutes: Int, icon: String, isDisabled: Bool = false) -> some View {
        Button(action: { onAdjustTimer(minutes) }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white)
                    .frame(minHeight: 12)
                
                Text("\(abs(minutes))m")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.7))
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(isDisabled ? .gray.opacity(0.3) : buttonBackgroundColor)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
        }
        .disabled(isDisabled)
    }
}

// MARK: - Timer Control Panel Computed Properties
private extension TimerControlPanel {
    var buttonBackgroundColor: Color {
        switch timerState.status {
        case .running:
            return .yellow.opacity(0.8)
        case .completed:
            return .orange.opacity(0.8)
        case .idle, .paused:
            return .gray.opacity(0.6)
        }
    }
    
    var playPauseIcon: String {
        switch timerState.status {
        case .idle, .paused:
            return "play.fill"
        case .completed:
            return "play.fill"
        case .running:
            return "pause.fill"
        }
    }
    
    var playPauseBackgroundColor: Color {
        switch timerState.status {
        case .idle, .paused:
            return .green.opacity(0.8)
        case .completed:
            return .blue.opacity(0.8)
        case .running:
            return .orange.opacity(0.8)
        }
    }
    
    var shouldDisableResetButton: Bool {
        timerState.status == .idle && timerState.remainingTime == timerState.duration
    }
    
    var shouldDisableAdjustButtons: Bool {
        timerState.status == .running
    }
}

// MARK: - Preview
struct TimerButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TimerButton(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running,
                    shouldPersistAfterCompletion: false
                ),
                onTap: {}
            )
            
            TimerControlPanel(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running,
                    shouldPersistAfterCompletion: false
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in },
                onClose: {}
            )
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
