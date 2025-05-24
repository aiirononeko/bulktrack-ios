import SwiftUI
import Domain

/// フローティングタイマーボタン
/// 画面右下に固定表示され、タップで操作パネルを展開
struct FloatingTimerButton: View {
    let timerState: TimerState
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onAdjustTimer: (Int) -> Void
    
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if isExpanded {
                    // 展開時の操作パネル
                    timerControlPanel
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    // 縮小時のメインボタン
                    mainTimerButton
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 100) // セット登録ボタンより上に配置
    }
}

// MARK: - Timer Control Panel
private extension FloatingTimerButton {
    var timerControlPanel: some View {
        HStack(spacing: 12) {
            // 時間調整ボタン（-1分）
            adjustButton(minutes: -1, icon: "minus", isDisabled: shouldDisableAdjustButtons || timerState.duration <= 60)
            
            // 再生/一時停止ボタン
            Button(action: onToggleTimer) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(playPauseBackgroundColor)
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                    )
            }
            .scaleEffect(timerState.isActive ? 1.0 : 0.95)
            .animation(.spring(response: 0.3), value: timerState.isActive)
            
            // 時間調整ボタン（+1分）
            adjustButton(minutes: 1, icon: "plus", isDisabled: shouldDisableAdjustButtons)
            
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
            
            // 閉じるボタン
            Button(action: {
                withAnimation {
                    isExpanded = false
                }
            }) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

// MARK: - Main Timer Button
private extension FloatingTimerButton {
    var mainTimerButton: some View {
        Button(action: {
            withAnimation {
                isExpanded = true
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: timerIconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(mainButtonBackgroundColor)
            )
        }
    }
}

// MARK: - Computed Properties
private extension FloatingTimerButton {
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
    
    var timerIconName: String {
        switch timerState.status {
        case .completed:
            return "checkmark.circle.fill"
        default:
            return "timer"
        }
    }
    
    var statusColor: Color {
        switch timerState.status {
        case .running:
            return .yellow
        case .paused:
            return .orange
        case .completed:
            return .white
        case .idle:
            return .white.opacity(0.6)
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
struct FloatingTimerButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            FloatingTimerButton(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running,
                    shouldPersistAfterCompletion: false
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
        }
    }
}
