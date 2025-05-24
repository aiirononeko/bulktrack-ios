import SwiftUI
import Domain

/// シンプルなバナー形式のタイマーUI
/// 左側にアイコンとタイマー表示、右側にコントロールボタン群を配置
struct TimerBannerView: View {
    let timerState: TimerState
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onAdjustTimer: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側：タイマーアイコンと時間表示
            timerDisplaySection
            
            Spacer()
            
            // 右側：コントロールボタン群
            controlButtonsSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private extension TimerBannerView {
    var timerDisplaySection: some View {
        HStack(spacing: 12) {
            // タイマーアイコン
            Image(systemName: "timer")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 24, height: 24)
            
            // 残り時間表示
            Text(timerState.formattedRemainingTime)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .animation(.none, value: timerState.formattedRemainingTime)
            
            // 状態インジケータ
            statusIndicator
        }
    }
    
    var statusIndicator: some View {
        HStack(spacing: 6) {
            // 状態インジケータドット
            Circle()
                .fill(.yellow)
                .frame(width: 8, height: 8)
                .scaleEffect(timerState.isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timerState.isActive)
        }
    }
    
    var controlButtonsSection: some View {
        HStack(spacing: 8) {
            // +1分ボタン
            adjustButton(minutes: 1, icon: "plus")
            
            // -1分ボタン
            adjustButton(minutes: -1, icon: "minus", isDisabled: timerState.duration <= 60)

            // 再生/一時停止ボタン
            Button(action: onToggleTimer) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.yellow)
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
                    .font(.system(size: 14, weight: .medium))
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
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.8))
                    .frame(minHeight: 10)
                
                Text("\(abs(minutes))m")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.6))
            }
            .frame(width: 36, height: 36)
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
}

private extension TimerBannerView {
    var statusColor: Color {
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
    
    var statusText: String {
        switch timerState.status {
        case .running:
            return "実行中"
        case .paused:
            return "一時停止"
        case .completed:
            return "完了"
        case .idle:
            return "待機中"
        }
    }
    
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
}

// MARK: - Preview
struct TimerBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // アイドル状態
            TimerBannerView(
                timerState: .defaultTimer(),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            // 実行中
            TimerBannerView(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            // 一時停止中
            TimerBannerView(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 90,
                    status: .paused
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            // 完了状態
            TimerBannerView(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 0,
                    status: .completed
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}
