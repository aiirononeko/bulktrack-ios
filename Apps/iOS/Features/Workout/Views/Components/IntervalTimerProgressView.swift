import SwiftUI
import Domain

/// インターバルタイマーのプログレスバー表示コンポーネント
/// ブロック形式でタイマーの進行状況を表示し、右端にタイマー時間を表示
struct IntervalTimerProgressView: View {
    let timerState: TimerState
    
    @Environment(\.colorScheme) var colorScheme
    
    private let totalBlocks = 20
    
    var body: some View {
        HStack(spacing: 8) {
            // プログレスバー（ブロック形式）
            HStack(spacing: 2) {
                ForEach(0..<totalBlocks, id: \.self) { index in
                    Rectangle()
                        .fill(blockColor(for: index))
                        .frame(height: 30)
                        .cornerRadius(2)
                }
            }
            .frame(maxWidth: .infinity)
            
            // タイマー時間表示
            Text(timerState.formattedRemainingTime)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(timerTextColor)
                .animation(.none, value: timerState.formattedRemainingTime)
                .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 28)
        .background(backgroundColor)
    }
}

// MARK: - Helper Methods
private extension IntervalTimerProgressView {
    /// インデックスに基づいてブロックの色を決定
    /// progressが減っていくにつれて右側からブロックが減っていく仕様
    func blockColor(for index: Int) -> Color {
        let progress = timerState.progress
        let reversedIndex = totalBlocks - 1 - index
        let blockThreshold = Double(reversedIndex + 1) / Double(totalBlocks)
        
        if progress >= blockThreshold {
            // 時間が経過したブロック
            return inactiveBlockColor
        } else {
            return activeBlockColor
        }
    }
    
    /// アクティブなブロックの色
    var activeBlockColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    /// 非アクティブなブロックの色
    var inactiveBlockColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2)
    }
    
    /// タイマーテキストの色
    var timerTextColor: Color {
        switch timerState.status {
        case .running:
            return colorScheme == .dark ? .white : .black
        case .completed:
            return .orange
        case .idle, .paused:
            return Color(.secondaryLabel)
        }
    }
    
    /// 背景色
    var backgroundColor: Color {
        switch timerState.status {
        case .running:
            return Color(.systemBackground)
        case .completed:
            return Color(.systemBackground)
        case .idle, .paused:
            return Color(.systemBackground)
        }
    }
}

// MARK: - Preview
struct IntervalTimerProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // アイドル状態
            IntervalTimerProgressView(
                timerState: .defaultTimer()
            )
            
            // 実行中（50%進行）
            IntervalTimerProgressView(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 90,
                    status: .running,
                    shouldPersistAfterCompletion: false
                )
            )
            
            // 実行中（80%進行）
            IntervalTimerProgressView(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 36,
                    status: .running,
                    shouldPersistAfterCompletion: false
                )
            )
            
            // 完了状態
            IntervalTimerProgressView(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 0,
                    status: .completed,
                    shouldPersistAfterCompletion: true
                )
            )
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
