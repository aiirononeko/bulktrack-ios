//
//  ContentView.swift
//  BulkTrack Watch App
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some View {
        TabView {
            // 1ページ目: 最近の種目
            RecentWorkoutsView()
                .environmentObject(sessionManager)

            // 2ページ目: 全ての種目
            AllExercisesView()
                .environmentObject(sessionManager)
        }
        .tabViewStyle(.page(indexDisplayMode: .never)) // 横スワイプでページ切り替え、インジケータなし
    }
}

// 最近の種目リストを表示するビュー (元のContentViewのロジックを移動)
struct RecentWorkoutsView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = sessionManager.errorMessage {
                    Text("エラー: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }

                if sessionManager.recentWorkouts.isEmpty && sessionManager.errorMessage == nil {
                    Text("最近の種目はありません。\niPhoneアプリで記録を開始してください。")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("データを再取得") {
                        sessionManager.requestRecentWorkoutsFromPhone()
                    }
                    .padding(.top)
                } else {
                    List {
                        ForEach(sessionManager.recentWorkouts) { workout in
                            NavigationLink(destination: WorkoutRecordingView(selectedWorkout: workout)) {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.traditional") // 仮のアイコン
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading) {
                                        Text(workout.name)
                                            .font(.headline)
                                    }
                                    Spacer()
                                    // NavigationLinkが自動的に右向きの > を表示するので、手動のChevronは不要な場合が多い
                                    // Image(systemName: "chevron.right")
                                    //      .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .navigationTitle("最近の種目")
                    .onAppear {
                        // 必要に応じてデータをリクエスト
                        // sessionManager.requestRecentWorkoutsFromPhone()
                    }
                }
            }
        }
    }
}

// 日付フォーマッタ (必要に応じて ContentView 内や別の場所に移動)
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    ContentView()
        .environmentObject(WatchSessionManager.shared) // PreviewでもManagerを注入
}
