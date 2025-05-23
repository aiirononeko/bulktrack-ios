import SwiftUI
import Domain // ExerciseEntity を使用するため

struct StartWorkoutSheetView: View {
    @Environment(\.dismiss) var dismiss
    var onExerciseSelected: (ExerciseEntity) -> Void // 親Viewに選択されたエクササイズを通知するコールバック
    @StateObject var viewModel: StartWorkoutSheetViewModel // ViewModel を StateObject として保持
    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) { // spacingを0に
                Picker("種目選択", selection: $selectedTab) {
                    Text("最近行った種目").tag(0)
                    Text("すべての種目").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding() // 上下左右にパディング

                TabView(selection: $selectedTab) {
                    exerciseListView(
                        exercises: viewModel.recentExercises,
                        isLoading: viewModel.isLoadingRecent,
                        errorMessage: viewModel.errorMessageRecent,
                        emptyMessage: "最近行った種目はありません。",
                        isSearchable: false,
                        searchText: .constant(""), // searchTextを渡すが使わない
                        isSearchFieldFocused: $isSearchFieldFocused
                    )
                    .tag(0)

                    exerciseListView(
                        exercises: viewModel.allExercises,
                        isLoading: viewModel.isLoadingAll,
                        errorMessage: viewModel.errorMessageAll,
                        emptyMessage: "種目がありません。",
                        isSearchable: true,
                        searchText: $searchText,
                        isSearchFieldFocused: $isSearchFieldFocused
                    )
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .onAppear {
                loadInitialData()
            }
            .onChange(of: selectedTab) { newTab in
                // タブ変更時に検索テキストをクリアし、フォーカスを外す
                searchText = ""
                isSearchFieldFocused = false
                if newTab == 0 {
                    viewModel.loadRecentExercises()
                } else {
                    viewModel.loadAllExercises(query: nil) // 初期ロード時はクエリなし
                }
            }
            .onChange(of: searchText) { newValue in
                // 検索テキストが変更されたら、すべての種目タブの場合のみAPIを叩く
                if selectedTab == 1 {
                    // ユーザーがタイピングを終えるのを待つために少し遅延させる (debounce)
                    // ここでは簡易的に直接呼び出すが、実際には .debounce を使うのが望ましい
                    viewModel.loadAllExercises(query: newValue.isEmpty ? nil : newValue)
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
        .interactiveDismissDisabled(isSearchFieldFocused) // キーボード表示中は下スワイプでのシート解除を無効化 (iOS 15+)
        // 上記はシートが全画面になる挙動とは直接関係ないが、UX向上のため検討
    }

    private func loadInitialData() {
        if selectedTab == 0 {
            viewModel.loadRecentExercises()
        } else {
            viewModel.loadAllExercises(query: searchText.isEmpty ? nil : searchText)
        }
    }

    // プライベートメソッドとして種目リストビューを定義
    @ViewBuilder
    private func exerciseListView(
        exercises: [ExerciseEntity],
        isLoading: Bool,
        errorMessage: String?,
        emptyMessage: String,
        isSearchable: Bool,
        searchText: Binding<String>,
        isSearchFieldFocused: FocusState<Bool>.Binding
    ) -> some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                Text("エラー: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if exercises.isEmpty && (!isSearchable || searchText.wrappedValue.isEmpty) { // 検索時で結果0件は別途表示
                Text(emptyMessage)
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if exercises.isEmpty && isSearchable && !searchText.wrappedValue.isEmpty {
                Text("\"\(searchText.wrappedValue)\" に一致する種目はありません。")
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) { // カード間のスペース
                        ForEach(exercises) { exercise in
                            ExerciseCardView(exercise: exercise)
                                .onTapGesture {
                                    isSearchFieldFocused.wrappedValue = false // キーボードを閉じる
                                    onExerciseSelected(exercise) // 選択されたエクササイズを通知
                                    // dismiss() // ここではシートを閉じない
                                }
                        }
                    }
                    .padding(.horizontal) // 左右のパディング
                    .padding(.top) // 上部のパディング
                }
            }

            if isSearchable {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("種目を検索", text: searchText)
                        .focused(isSearchFieldFocused)
                        .submitLabel(.search) // キーボードのReturnキーを「検索」に
                        .onSubmit {
                            // ユーザーがReturnキーを押した時の処理 (必要であれば)
                            // onChange(of: searchText) で既に処理しているので、ここでは不要かも
                        }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSearchFieldFocused.wrappedValue ? Color.primary : Color.clear, lineWidth: isSearchFieldFocused.wrappedValue ? 1 : 0)
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                .padding(.top, 8)
            }
        }
    }
}
