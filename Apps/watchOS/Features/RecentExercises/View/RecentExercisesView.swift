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
                if vm.isLoading {
                    ProgressView("読み込み中…")
                } else if let e = vm.errorMessage {
                    VStack(spacing: 8) {
                        Text("エラー: \(e)").foregroundColor(.red)
                        Button("再試行") { vm.fetchRecentExercises() }
                    }
                } else if vm.exercises.isEmpty {
                    VStack {
                        Text("最近の種目がありません")
                        Button("取得する") { vm.fetchRecentExercises() }
                    }
                } else {
                    List(vm.exercises) { exercise in
                        NavigationLink(exercise.name) {
//                            ExerciseDetailView(exercise: exercise) // 任意の遷移先
                        }
                    }
                }
            }
            .navigationTitle("最近の種目")
        }
        .task {          // View が表示されたら 1 度だけ
            vm.fetchRecentExercises()
        }
    }
}
