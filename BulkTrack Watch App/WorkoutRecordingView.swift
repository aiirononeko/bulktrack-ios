import SwiftUI

struct WorkoutRecordingView: View {
    let selectedWorkout: WorkoutData // 選択された種目データを受け取る

    var body: some View {
        VStack(spacing: 10) {
            // Text("トレーニング記録")
            //     .font(.title3)
            
            Text("種目: \(selectedWorkout.name)")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // TODO: ここにセット数、重量、回数などの入力UIを将来的に追加
            Text("セット: 1")
            Text("重量: -- kg")
            Text("回数: -- 回")
            
            // Button(action: {
            //     // TODO: 記録処理
            //     print("記録開始ボタンがタップされました。種目ID: \(selectedWorkout.id)")
            // }) {
            //     Text("記録開始")
            //         .padding()
            //         .frame(maxWidth: .infinity)
            //         .background(Color.green)
            //         .foregroundColor(.white)
            //         .cornerRadius(10)
            // }
            
            Spacer()
        }
        .padding()
        .navigationTitle(selectedWorkout.name) // ナビゲーションバーのタイトル
    }
}

#Preview {
    // Preview用にダミーデータを作成
    let dummyWorkout = WorkoutData(id: "preview-dummy-id", name: "ダミー種目")
    return NavigationView { // Previewでタイトルバーを表示するためNavigationViewで囲む
         WorkoutRecordingView(selectedWorkout: dummyWorkout)
    }
}
