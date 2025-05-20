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

                if sessionManager.isLoading {
                    // ローディングアニメーション
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("データを取得中...")
                        .font(.headline)
                        .padding(.top)
                    Spacer()
                } else if sessionManager.allAvailableExercises.isEmpty {
                    if sessionManager.errorMessage != nil && sessionManager.allAvailableExercises.isEmpty {
                        // エラーメッセージはRecentWorkoutsView側で表示される想定だが、こちらでも表示するなら別途考慮
                         Text("エラーが発生しました。")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Spacer()
                        Text("種目がありません。\nデータを取得します。")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .padding()
                        
                        Button(action: {
                            sessionManager.requestAllExercises()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top)
                        
                        Spacer()
                    }
                } else {
                    VStack {
                        List {
                            // TODO: 検索結果でフィルタリングするロジック
                            // ForEach(sessionManager.allAvailableExercises.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }) { exercise in
                            ForEach(sessionManager.allAvailableExercises) { exercise in
                                NavigationLink(destination: TabWorkoutView(selectedWorkout: exercise)) {
                                    HStack {
                                        // ここでも各種目に合わせたアイコンを表示できると良い
                                        Image(systemName: "figure.run") // 仮のアイコン
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.blue) // 色を変えて区別
                                        VStack(alignment: .leading) {
                                            Text(exercise.name)
                                                .font(.headline)
                                            if exercise.name.hasPrefix("種目 ") {
                                                Text("ID: \(exercise.id)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                        // Image(systemName: "chevron.right") // 詳細画面がない場合は不要
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        Button(action: {
                            sessionManager.requestAllExercises()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("全ての種目")
            .onAppear {
                // Viewが表示されるたびにデータをリクエスト
                sessionManager.requestAllExercises()
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
