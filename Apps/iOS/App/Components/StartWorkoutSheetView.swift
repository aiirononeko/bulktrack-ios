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
                .padding(.top)
                .padding(.horizontal)

                TabView(selection: $selectedTab) {
                    exerciseListView(
                        exercises: viewModel.recentExercises,
                        isLoading: viewModel.isLoadingRecent,
                        errorMessage: viewModel.errorMessageRecent,
                        emptyMessage: "最近行った種目はありません。"
                    )
                    .tag(0)

                    exerciseListView(
                        exercises: viewModel.allExercises,
                        isLoading: viewModel.isLoadingAll,
                        errorMessage: viewModel.errorMessageAll,
                        emptyMessage: "種目がありません。"
                    )
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // インジケーターを非表示にし、スワイプで切り替え可能に

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

    // プライベートメソッドとして種目リストビューを定義
    @ViewBuilder
    private func exerciseListView(
        exercises: [ExerciseEntity],
        isLoading: Bool,
        errorMessage: String?,
        emptyMessage: String
    ) -> some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = errorMessage {
            Text("エラー: \(errorMessage)")
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if exercises.isEmpty {
            Text(emptyMessage)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) { // カード間のスペース
                    ForEach(exercises) { exercise in
                        ExerciseCardView(exercise: exercise)
                    }
                }
                .padding(.horizontal) // 左右のパディング
                .padding(.top) // 上部のパディング
            }
        }
    }
}
