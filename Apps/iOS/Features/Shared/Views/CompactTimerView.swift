import SwiftUI
import Domain
import Combine

/// 縮小化されたタイマーUI
/// 筋トレ記録画面以外の全画面で表示される
struct CompactTimerView: View {
    @ObservedObject var globalTimerViewModel: GlobalTimerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if globalTimerViewModel.hasActiveTimer {
            HStack(spacing: 12) {
                // タイマー表示部分
                VStack(alignment: .leading, spacing: 2) {
                    Text(globalTimerViewModel.displayTimerState.formattedRemainingTime)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("インターバルタイマー")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作ボタン
                HStack(spacing: 8) {
                    // 再生/停止ボタン
                    Button(action: {
                        globalTimerViewModel.toggleTimer()
                    }) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    // エクササイズ画面に戻るボタン
                    Button(action: {
                        globalTimerViewModel.navigateToExercise()
                    }) {
                        Image(systemName: "arrow.up.left.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(timerBorderColor, lineWidth: 2)
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Computed Properties
    private var playPauseIcon: String {
        switch globalTimerViewModel.displayTimerState.status {
        case .idle, .completed:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }
    
    private var timerBorderColor: Color {
        switch globalTimerViewModel.displayTimerState.status {
        case .idle:
            return .gray.opacity(0.3)
        case .running:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        }
    }
}
