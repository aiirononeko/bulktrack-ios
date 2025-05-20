import SwiftUI

struct TabWorkoutView: View {
    let selectedWorkout: WorkoutData // 選択された種目データを受け取る
    @State private var selectedIndex = 1 // デフォルトで中央（筋トレ記録）を表示
    @Environment(\.presentationMode) private var presentationMode // 戻るボタン用
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $selectedIndex) {
                // 左側のページ: インターバルタイマー
                IntervalTimerView()
                    .tag(0)
                
                // 中央のページ（デフォルト表示）: 筋トレ記録画面
                WorkoutRecordingView(selectedWorkout: selectedWorkout)
                    .tag(1)
                
                // 右側のページ: Spotify音楽
                SpotifyMusicView()
                    .tag(2)
            }
            .tabViewStyle(.page)
            .navigationBarBackButtonHidden(true) // デフォルトの戻るボタンを非表示

        }
    }
}

#Preview {
    // プレビュー用のダミーデータ
    let dummyWorkout = WorkoutData(id: "preview-dummy-id", name: "ダミーベンチプレス")
    return TabWorkoutView(selectedWorkout: dummyWorkout)
        .environmentObject(WatchSessionManager.shared)
}
