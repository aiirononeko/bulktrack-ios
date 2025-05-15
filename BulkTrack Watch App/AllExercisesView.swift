import SwiftUI

struct AllExercisesView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                // TODO: 検索バーをここに追加する (オプション)
                // TextField("種目を検索", text: $searchText)
                //     .padding()

                if sessionManager.allAvailableExercises.isEmpty {
                    if sessionManager.errorMessage != nil && sessionManager.allAvailableExercises.isEmpty {
                        // エラーメッセージはRecentWorkoutsView側で表示される想定だが、こちらでも表示するなら別途考慮
                         Text("エラーが発生しました。")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Text("利用可能な種目がありません。\niPhoneからデータを取得します。")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("全種目を取得") {
                            sessionManager.requestAllExercises() // このメソッドは後でWatchSessionManagerに追加
                        }
                        .padding(.top)
                    }
                } else {
                    List {
                        // TODO: 検索結果でフィルタリングするロジック
                        // ForEach(sessionManager.allAvailableExercises.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }) { exercise in
                        ForEach(sessionManager.allAvailableExercises) { exercise in
                            NavigationLink(destination: WorkoutRecordingView(selectedWorkout: exercise)) {
                                HStack {
                                    // ここでも各種目に合わせたアイコンを表示できると良い
                                    Image(systemName: "figure.run") // 仮のアイコン
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.blue) // 色を変えて区別
                                    Text(exercise.name)
                                        .font(.headline)
                                    Spacer()
                                    // Image(systemName: "chevron.right") // 詳細画面がない場合は不要
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("全ての種目")
            .onAppear {
                // Viewが表示された初回にデータをリクエスト
                if sessionManager.allAvailableExercises.isEmpty {
                    sessionManager.requestAllExercises() // このメソッドは後でWatchSessionManagerに追加
                }
            }
        }
    }
}

#Preview {
    // Preview用にダミーデータを持つWatchSessionManagerを準備
    let previewManager = WatchSessionManager.shared
    // previewManager.allAvailableExercises = [
    //     WorkoutData(id: "ex1", name: "ベンチプレス"),
    //     WorkoutData(id: "ex2", name: "スクワット"),
    //     WorkoutData(id: "ex3", name: "デッドリフト")
    // ]
    return AllExercisesView()
        .environmentObject(previewManager)
} 