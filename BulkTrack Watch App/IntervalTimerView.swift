import SwiftUI

struct IntervalTimerView: View {
    @State private var minutes: Int = 1
    @State private var seconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var remainingSeconds: Int = 60
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("インターバルタイマー")
                .font(.headline)
            
            if isRunning {
                // タイマー実行中の表示
                Text(timeString(seconds: remainingSeconds))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(remainingSeconds < 10 ? .red : .primary)
                
                Button(action: stopTimer) {
                    Text("停止")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                // タイマーセットアップUI
                HStack {
                    Picker("分", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .frame(width: 50)
                    .clipped()
                    
                    Text("分")
                    
                    Picker("秒", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { second in
                            Text("\(second)").tag(second)
                        }
                    }
                    .frame(width: 50)
                    .clipped()
                    
                    Text("秒")
                }
                
                Button(action: startTimer) {
                    Text("開始")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .navigationTitle("タイマー")
    }
    
    // タイマー開始
    func startTimer() {
        let totalSeconds = minutes * 60 + seconds
        guard totalSeconds > 0 else { return }
        
        remainingSeconds = totalSeconds
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stopTimer()
                // ここで通知音や振動を追加できます
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
    
    // タイマー停止
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    // 秒数を「MM:SS」形式に変換
    func timeString(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    IntervalTimerView()
}
