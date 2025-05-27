import SwiftUI
import Domain

/// 画面上部に表示するグローバルタイマーバー
/// 黄色背景で中央にタイマー時間、右側に「トレーニングに戻る」テキストを表示
struct TopTimerBarView: View {
    @ObservedObject var globalTimerViewModel: GlobalTimerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if globalTimerViewModel.hasActiveTimer {
            HStack {
                // 中央のタイマー表示
                HStack(spacing: 8) {
                    Image(systemName: timerIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text(globalTimerViewModel.displayTimerState.formattedRemainingTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textColor)
                }
                .frame(maxWidth: .infinity)
                
                // 右側の「トレーニングに戻る」テキスト
                HStack(spacing: 4) {
                    Text("トレーニングに戻る")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor)
                }
                .padding(.trailing, 16)
            }
            .frame(height: 44)
            .background(backgroundColor)
            .contentShape(Rectangle()) // タップ領域を全体に拡張
            .onTapGesture {
                globalTimerViewModel.navigateToExercise()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Computed Properties
    private var timerIcon: String {
        switch globalTimerViewModel.displayTimerState.status {
        case .idle:
            return "timer"
        case .running:
            return "timer.circle"
        case .paused:
            return "pause.circle"
        case .completed:
            return "checkmark.circle"
        }
    }
    
    private var backgroundColor: Color {
        // ライトモード: 黒、ダークモード: 白
        return colorScheme == .dark ? .white : .black
    }
    
    private var textColor: Color {
        // 背景色に対するコントラスト色
        return colorScheme == .dark ? .black : .white
    }
}
