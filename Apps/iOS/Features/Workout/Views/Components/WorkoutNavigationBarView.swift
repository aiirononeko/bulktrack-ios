import SwiftUI
import Domain

/// 筋トレ画面専用の簡素なナビゲーションバー
/// 種目名と戻るボタンのみ表示
struct WorkoutNavigationBarView: View {
    let exerciseName: String
    let timerState: TimerState
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Dynamic Island対応の上部スペース
            Rectangle()
                .fill(Color(.systemBackground))
                .frame(height: 16)
            
            // メインナビゲーションエリア
            HStack(spacing: 16) {
                // 左側：戻るボタン（シンプル）
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(.label))
                }
                .frame(width: 44, height: 44)
                
                Spacer()
                
                Text(exerciseName)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // プレースホルダー（右側のバランス用）
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .frame(height: 44) // 標準のナビゲーションバーの高さ
            .background(Color(.systemBackground))
            
            // 下部のボーダーライン
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
        .background(Color(.systemBackground))
    }
}


// MARK: - Preview
struct WorkoutNavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // アイドル状態
            WorkoutNavigationBarView(
                exerciseName: "ベンチプレス",
                timerState: .defaultTimer(),
                onDismiss: {}
            )
            
            // 実行中
            WorkoutNavigationBarView(
                exerciseName: "スクワット",
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running,
                    shouldPersistAfterCompletion: false
                ),
                onDismiss: {}
            )
            
            // 完了状態
            WorkoutNavigationBarView(
                exerciseName: "デッドリフト",
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 0,
                    status: .completed,
                    shouldPersistAfterCompletion: true
                ),
                onDismiss: {}
            )
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}
