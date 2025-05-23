import SwiftUI
import Domain

/// 右上に表示されるタイマーアイコンボタン
struct IntervalTimerButton: View {
    let timerState: TimerState
    let uiState: TimerUIState
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // タイマーアイコンまたは時間表示
                Group {
                    if case .collapsed(let isRunning) = uiState, isRunning {
                        // 実行中は残り時間を表示
                        Text(timerState.formattedRemainingTime)
                            .font(.caption)
                            .fontWeight(.medium)
                            .monospacedDigit()
                            .foregroundColor(.white)
                    } else {
                        // 停止中はタイマーアイコンを表示
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // 展開/収縮状態を示すインジケータ
                if uiState.isExpanded {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                backgroundView
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private extension IntervalTimerButton {
    @ViewBuilder
    var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundGradient)
            .overlay(
                // プログレスインジケータ（実行中のみ）
                progressOverlay
            )
            .overlay(
                // ボーダー
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    var backgroundGradient: LinearGradient {
        switch timerState.status {
        case .running:
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .paused:
            return LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .completed:
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .idle:
            return LinearGradient(
                colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var borderColor: Color {
        switch timerState.status {
        case .running:
            return Color.green.opacity(0.3)
        case .paused:
            return Color.orange.opacity(0.3)
        case .completed:
            return Color.blue.opacity(0.3)
        case .idle:
            return Color.gray.opacity(0.3)
        }
    }
    
    @ViewBuilder
    var progressOverlay: some View {
        if timerState.isActive {
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: geometry.size.width * (1.0 - timerState.progress))
                    .animation(.linear(duration: 1), value: timerState.progress)
            }
        }
    }
}

// MARK: - Preview
struct IntervalTimerButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // アイドル状態
            IntervalTimerButton(
                timerState: .defaultTimer(),
                uiState: .collapsed(isRunning: false),
                onTap: {}
            )
            
            // 実行中
            IntervalTimerButton(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running
                ),
                uiState: .collapsed(isRunning: true),
                onTap: {}
            )
            
            // 展開状態
            IntervalTimerButton(
                timerState: .defaultTimer(),
                uiState: .expanded,
                onTap: {}
            )
            
            // 完了状態
            IntervalTimerButton(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 0,
                    status: .completed
                ),
                uiState: .collapsed(isRunning: false),
                onTap: {}
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
