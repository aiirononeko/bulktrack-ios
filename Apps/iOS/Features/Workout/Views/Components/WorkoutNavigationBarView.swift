import SwiftUI
import Domain

/// 筋トレ画面専用のナビゲーションバー
/// 種目名とインターバルタイマーを統合表示
struct WorkoutNavigationBarView: View {
    let exerciseName: String
    let timerState: TimerState
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // メインナビゲーションエリア
            HStack(spacing: 16) {
                // 左側：戻るボタン（シンプル）
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor)
                }
                .frame(width: 44, height: 44)
                
                Spacer()
                
                Text(exerciseName)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text(timerState.formattedRemainingTime)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(textColor.opacity(0.9))
                    .animation(.none, value: timerState.formattedRemainingTime)
            }
            .padding(.horizontal, 16)
            .frame(height: 44) // 標準のナビゲーションバーの高さ
            .background(navigationBackgroundColor)
            
            // 下部のボーダーライン
            Rectangle()
                .fill(borderColor)
                .frame(height: 0.5)
        }
        .background(navigationBackgroundColor)
    }
}

// MARK: - Computed Properties
private extension WorkoutNavigationBarView {
    var navigationBackgroundColor: Color {
        switch timerState.status {
        case .running:
            return .yellow
        case .completed:
            return Color(.systemBackground)
        case .idle, .paused:
            return Color(.systemBackground)
        }
    }
    
    var textColor: Color {
        switch timerState.status {
        case .running:
            // イエロー背景時は常に黒文字で視認性を確保
            return .black
        case .completed, .idle, .paused:
            // システム背景色に応じて動的に変更
            return Color(.label)
        }
    }
    
    var borderColor: Color {
        switch timerState.status {
        case .running:
            return .yellow.opacity(0.3)
        case .completed:
            return .orange.opacity(0.3)
        case .idle, .paused:
            return Color(.separator)
        }
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
