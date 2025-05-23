import SwiftUI
import Domain

/// 展開時のタイマーコントロールパネル
struct IntervalTimerPanel: View {
    let timerState: TimerState
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onAdjustTimer: (Int) -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // メインタイマーコントロール部分
            timerControlsSection
            
            // 閉じるボタン
            closeButton
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

private extension IntervalTimerPanel {
    var timerControlsSection: some View {
        HStack(spacing: 20) {
            // 時間調整ボタン（-1分）
            adjustButton(minutes: -1, icon: "minus", isDisabled: timerState.duration <= 60)
            
            // メインタイマー表示とコントロール
            timerDisplaySection
            
            // 時間調整ボタン（+1分）
            adjustButton(minutes: 1, icon: "plus")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    var timerDisplaySection: some View {
        VStack(spacing: 12) {
            // 残り時間表示
            Text(timerState.formattedRemainingTime)
                .font(.system(.title, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .animation(.none, value: timerState.formattedRemainingTime)
            
            // プログレスバー
            progressBar
            
            // 制御ボタン
            controlButtons
        }
        .frame(minWidth: 120)
    }
    
    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
                
                // プログレス
                RoundedRectangle(cornerRadius: 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * timerState.progress, height: 4)
                    .animation(.linear(duration: 1), value: timerState.progress)
            }
        }
        .frame(height: 4)
    }
    
    var controlButtons: some View {
        HStack(spacing: 16) {
            // 再生/一時停止ボタン
            Button(action: onToggleTimer) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(playPauseBackgroundColor)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .scaleEffect(timerState.isActive ? 1.0 : 0.95)
            .animation(.spring(response: 0.3), value: timerState.isActive)
            
            // リセットボタン
            Button(action: onResetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .disabled(timerState.status == .idle && timerState.remainingTime == timerState.duration)
        }
    }
    
    func adjustButton(minutes: Int, icon: String, isDisabled: Bool = false) -> some View {
        Button(action: { onAdjustTimer(minutes) }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.8))
                
                Text("\(abs(minutes))分")
                    .font(.caption2)
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.6))
            }
            .frame(width: 44, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDisabled ? .clear : .white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(isDisabled ? 0.1 : 0.2), lineWidth: 1)
                    )
            )
        }
        .disabled(isDisabled)
    }
    
    var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.white.opacity(0.1))
                )
        }
        .padding(.trailing, 12)
    }
}

private extension IntervalTimerPanel {
    var playPauseIcon: String {
        switch timerState.status {
        case .idle, .paused, .completed:
            return "play.fill"
        case .running:
            return "pause.fill"
        }
    }
    
    var playPauseBackgroundColor: Color {
        switch timerState.status {
        case .idle, .paused, .completed:
            return .green.opacity(0.8)
        case .running:
            return .orange.opacity(0.8)
        }
    }
    
    var progressColor: Color {
        switch timerState.status {
        case .running:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        case .idle:
            return .white.opacity(0.6)
        }
    }
}

// MARK: - Preview
struct IntervalTimerPanel_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // アイドル状態
            IntervalTimerPanel(
                timerState: .defaultTimer(),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in },
                onClose: {}
            )
            
            // 実行中
            IntervalTimerPanel(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in },
                onClose: {}
            )
            
            // 一時停止中
            IntervalTimerPanel(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 90,
                    status: .paused
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in },
                onClose: {}
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
