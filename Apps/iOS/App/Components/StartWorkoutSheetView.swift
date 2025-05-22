import SwiftUI
import Domain // ExerciseEntity を使用するため

struct StartWorkoutSheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: StartWorkoutSheetViewModel // ViewModel を StateObject として保持
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                Picker("種目選択", selection: $selectedTab) {
                    Text("最近行った種目").tag(0)
                    Text("すべての種目").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedTab == 0 { // 最近行った種目
                    if viewModel.isLoadingRecent {
                        ProgressView()
                    } else if let errorMessage = viewModel.errorMessageRecent {
                        Text("エラー: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if viewModel.recentExercises.isEmpty {
                        Text("最近行った種目はありません。")
                    } else {
                        List(viewModel.recentExercises) { exercise in
                            Text(exercise.name)
                        }
                    }
                } else { // すべての種目
                    if viewModel.isLoadingAll {
                        ProgressView()
                    } else if let errorMessage = viewModel.errorMessageAll {
                        Text("エラー: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if viewModel.allExercises.isEmpty {
                        Text("種目がありません。")
                    } else {
                        List(viewModel.allExercises) { exercise in
                            Text(exercise.name)
                        }
                    }
                }

                Spacer()
            }
            .onAppear {
                // 初期表示時に選択されているタブのデータをロード
                if selectedTab == 0 {
                    viewModel.loadRecentExercises()
                } else {
                    viewModel.loadAllExercises()
                }
            }
            .onChange(of: selectedTab) { newTab in
                if newTab == 0 {
                    viewModel.loadRecentExercises()
                } else {
                    viewModel.loadAllExercises()
                }
            }
            .navigationTitle("トレーニングを開始する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
