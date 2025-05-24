import SwiftUI
import Domain

/// 画面上部に表示するグローバルタイマーバー
/// 黄色背景で中央にタイマー時間、右側に「トレーニングに戻る」テキストを表示
struct TopTimerBarView: View {
    @ObservedObject var globalTimerViewModel: GlobalTimerViewModel
    
    var body: some View {
        if globalTimerViewModel.hasActiveTimer {
            HStack {
                // 左側のスペーサー
                Spacer()
                
                // 中央のタイマー表示
                HStack(spacing: 8) {
                    Image(systemName: timerIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(globalTimerViewModel.displayTimerState.formattedRemainingTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                // 右側のスペーサー
                Spacer()
                
                // 右側の「トレーニングに戻る」テキスト
                HStack(spacing: 4) {
                    Text("トレーニングに戻る")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.trailing, 16)
            }
            .frame(height: 44)
            .background(Color.yellow)
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
}

#Preview {
    VStack {
        // プレビュー用の黄色バー（静的表示）
        HStack {
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "timer.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text("02:30")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("トレーニングに戻る")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(Color.yellow)
        
        Spacer()
        
        Text("メインコンテンツエリア")
            .font(.title)
            .foregroundColor(.secondary)
    }
}
