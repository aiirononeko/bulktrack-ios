//
//  RecentExercisesView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import SwiftUI

struct RecentExercisesView: View {
    @StateObject private var vm = RecentExercisesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch vm.recentExercisesState {
                case .idle:
                    // Initial state, or after a successful operation that results in no data
                    // For example, if fetch is only triggered by button press
                    VStack {
                        Text("データを取得してください。")
                        Button("取得する") { vm.fetchRecentExercises() }
                    }
                case .loading:
                    ProgressView("読み込み中…")
                case .success(let exercises):
                    if exercises.isEmpty {
                        VStack {
                            Text("最近の種目がありません")
                            Button("再取得する") { vm.fetchRecentExercises() }
                        }
                    } else {
                        List(exercises) { exercise in // Use the exercises from the success state
                            NavigationLink(exercise.name) {
                                // ExerciseDetailView(exercise: exercise) // 任意の遷移先
                            }
                        }
                    }
                case .failure(let error):
                    VStack(spacing: 8) {
                        Text("エラー: \(error.localizedDescription)").foregroundColor(.red)
                        Button("再試行") { vm.fetchRecentExercises() }
                    }
                }
            }
            .navigationTitle("最近の種目")
        }
        .task { // View が表示されたら 1 度だけ (または状態が.idleなら)
            if vm.recentExercisesState.isIdle {
                 vm.fetchRecentExercises()
            }
        }
    }
}
