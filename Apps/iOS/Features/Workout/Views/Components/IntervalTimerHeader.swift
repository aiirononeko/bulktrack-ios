import SwiftUI
import Domain

/// 上部エリアに固定表示されるタイマーヘッダー
struct IntervalTimerHeader: View {
    let timerState: TimerState
    let uiState: TimerUIState
    let onTap: () -> Void
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onAdjustTimer: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // コンパクト表示エリア（常時表示）
            compactTimerArea
            
            // 展開エリア（条件付き表示）
            if uiState.isExpanded {
                expandedTimerArea
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private extension IntervalTimerHeader {
    var compactTimerArea: some View {
        Button(action: onTap) {
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
                
                Spacer()
                
                // 状態インジケータ
                statusIndicator
                
                // 展開/折りたたみアイコン
                Image(systemName: uiState.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .rotationEffect(.degrees(uiState.isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.3), value: uiState.isExpanded)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var statusIndicator: some View {
        HStack(spacing: 6) {
            // 状態インジケータドット
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(timerState.isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timerState.isActive)
            
            // 状態テキスト
            Text(statusText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    var expandedTimerArea: some View {
        VStack(spacing: 16) {
            Divider()
                .background(.white.opacity(0.2))
            
            HStack(spacing: 20) {
                // 時間調整ボタン（-1分）
                adjustButton(minutes: -1, icon: "minus", isDisabled: timerState.duration <= 60)
                
                // プログレスバーとコントロール
                VStack(spacing: 12) {
                    // プログレスバー
                    progressBar
                    
                    // 制御ボタン
                    controlButtons
                }
                .frame(maxWidth: .infinity)
                
                // 時間調整ボタン（+1分）
                adjustButton(minutes: 1, icon: "plus")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.2))
                    .frame(height: 6)
                
                // プログレス
                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * timerState.progress, height: 6)
                    .animation(.linear(duration: 1), value: timerState.progress)
            }
        }
        .frame(height: 6)
    }
    
    var controlButtons: some View {
        HStack(spacing: 16) {
            // 再生/一時停止ボタン
            Button(action: onToggleTimer) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.8))
                
                Text("\(abs(minutes))分")
                    .font(.caption2)
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.6))
            }
            .frame(width: 40, height: 50)
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

private extension IntervalTimerHeader {
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
struct IntervalTimerHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // コンパクト表示（アイドル）
            IntervalTimerHeader(
                timerState: .defaultTimer(),
                uiState: .collapsed(isRunning: false),
                onTap: {},
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            // コンパクト表示（実行中）
            IntervalTimerHeader(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running
                ),
                uiState: .collapsed(isRunning: true),
                onTap: {},
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            // 展開表示
            IntervalTimerHeader(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 90,
                    status: .paused
                ),
                uiState: .expanded,
                onTap: {},
                onToggleTimer: {},
                onResetTimer: {},
                onAdjustTimer: { _ in }
            )
            
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}
