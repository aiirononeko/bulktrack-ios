import SwiftUI
import Domain

/// 改良されたタイマーボタン
/// - 1タップ: 開始/停止
/// - 2タップ: リセット
/// - 長押し: 操作パネル表示
struct TimerButton: View {
    let timerState: TimerState
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onShowControls: () -> Void
    let onSetDuration: ((Int) -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    @State private var scaleValue: CGFloat = 1.0
    @State private var pulseValue: CGFloat = 1.0
    @State private var showingTimerSheet = false
    
    var body: some View {
        VStack(spacing: 2) {
            Text(timerState.formattedRemainingTime)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(iconColor)
                .animation(.none, value: timerState.formattedRemainingTime)
        }
        .frame(width: 80, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(mainButtonBackgroundColor)
                .scaleEffect(pulseValue)
                .animation(.easeOut(duration: 0.3), value: pulseValue)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture(count: 2) {
            // ダブルタップでリセット
            triggerResetAnimation()
            onResetTimer()
        }
        .onTapGesture(count: 1) {
            // シングルタップで開始/停止
            triggerTapAnimation()
            onToggleTimer()
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
            // ハプティックフィードバック
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            triggerLongPressAnimation()
            showingTimerSheet = true
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }
        .sheet(isPresented: $showingTimerSheet) {
            TimerSettingsSheet { duration in
                onSetDuration?(duration)
            }
            .presentationDetents([.fraction(0.7)])
        }
    }
}

// MARK: - Computed Properties
private extension TimerButton {
    var mainButtonBackgroundColor: Color {
        // 統一カラーテーマ: ライトモード時は黒、ダークモード時は白
        return colorScheme == .dark ? .white : .black
    }
    
    var iconColor: Color {
        // 統一カラーテーマ: 背景の反対色
        return colorScheme == .dark ? .black : .white
    }
    
    var timerIconName: String {
        switch timerState.status {
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .idle:
            return "play.fill"
        }
    }
    
    // アニメーション関数
    private func triggerTapAnimation() {
        withAnimation(.easeInOut(duration: 0.1)) {
            scaleValue = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                scaleValue = 1.0
            }
        }
    }
    
    private func triggerResetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseValue = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                pulseValue = 1.0
            }
        }
    }
    
    private func triggerLongPressAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scaleValue = 1.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scaleValue = 1.0
            }
        }
    }
}

// MARK: - Timer Control Panel Component
struct TimerControlPanel: View {
    let timerState: TimerState
    let onAdjustTimer: (Int) -> Void
    let onClose: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMinutes: Int = 3
    @State private var selectedSeconds: Int = 0
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()
            
            VStack(alignment: .center, spacing: 12) {
                // タイマー時刻ピッカー（中央配置）
                HStack(spacing: 8) {
                    // 分ピッカー
                    VStack(spacing: 4) {
                        Text("分")
                            .font(.caption2)
                            .foregroundColor(textColor.opacity(0.7))
                        
                        Picker("分", selection: $selectedMinutes) {
                            ForEach(0...10, id: \.self) { minute in
                                Text("\(minute)")
                                    .font(.system(.title3, design: .monospaced))
                                    .foregroundColor(textColor)
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 80)
                        .clipped()
                    }
                    
                    Text(":")
                        .font(.title2)
                        .foregroundColor(textColor)
                        .padding(.top, 20)
                    
                    // 秒ピッカー（10秒単位）
                    VStack(spacing: 4) {
                        Text("秒")
                            .font(.caption2)
                            .foregroundColor(textColor.opacity(0.7))
                        
                        Picker("秒", selection: $selectedSeconds) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { second in
                                Text(String(format: "%02d", second))
                                    .font(.system(.title3, design: .monospaced))
                                    .foregroundColor(textColor)
                                    .tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 80)
                        .clipped()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            // パネル内のタップを捕捉してバックグラウンドのタップジェスチャーに伝播しないようにする
        }
        .onAppear {
            // 現在のタイマー時間を初期値として設定
            let totalSeconds = Int(timerState.duration)
            selectedMinutes = totalSeconds / 60
            selectedSeconds = (totalSeconds % 60 / 10) * 10  // 10秒単位に丸める
        }
        .onChange(of: selectedMinutes) { _, newMinutes in
            updateTimerDuration()
        }
        .onChange(of: selectedSeconds) { _, newSeconds in
            updateTimerDuration()
        }
    }
    
    private func adjustButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(buttonBackgroundColor)
                )
        }
    }
    
    private func updateTimerDuration() {
        let totalSeconds = selectedMinutes * 60 + selectedSeconds
        if totalSeconds > 0 {
            let minutesToAdjust = totalSeconds / 60 - Int(timerState.duration) / 60
            if minutesToAdjust != 0 {
                onAdjustTimer(minutesToAdjust)
            }
        }
    }
}

// MARK: - Timer Control Panel Computed Properties
private extension TimerControlPanel {
    var backgroundColor: Color {
        // インターバルタイマーカードは濃いめのグレー背景
        return Color(.systemGray4)
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var buttonBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1)
    }
}

// MARK: - Preview
struct TimerButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TimerButton(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running,
                    shouldPersistAfterCompletion: false
                ),
                onToggleTimer: {},
                onResetTimer: {},
                onShowControls: {},
                onSetDuration: { _ in }
            )
            
            TimerControlPanel(
                timerState: TimerState(
                    duration: 180,
                    remainingTime: 120,
                    status: .running,
                    shouldPersistAfterCompletion: false
                ),
                onAdjustTimer: { _ in },
                onClose: {}
            )
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .preferredColorScheme(.dark) // ダークモードプレビュー追加
    }
}
