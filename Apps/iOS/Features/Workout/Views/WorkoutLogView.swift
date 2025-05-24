import SwiftUI
import Domain

struct WorkoutLogView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WorkoutLogViewModel
    @StateObject private var globalTimerViewModel: GlobalTimerViewModel
    @FocusState private var focusedField: Field?
    @State private var showRPEHelp = false
    
    let exercise: ExerciseEntity
    
    enum Field: CaseIterable {
        case weight, reps, rpe
    }
    
    init(
        exercise: ExerciseEntity,
        saveWorkoutSetUseCase: SaveWorkoutSetUseCaseProtocol,
        getWorkoutHistoryUseCase: GetWorkoutHistoryUseCaseProtocol,
        globalTimerViewModel: GlobalTimerViewModel
    ) {
        self.exercise = exercise
        self._viewModel = StateObject(wrappedValue: WorkoutLogViewModel(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            saveWorkoutSetUseCase: saveWorkoutSetUseCase,
            getWorkoutHistoryUseCase: getWorkoutHistoryUseCase
        ))
        self._globalTimerViewModel = StateObject(wrappedValue: globalTimerViewModel)
        
        print("[WorkoutLogView] Init with exercise: \(exercise.name) (ID: \(exercise.id))")
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // カスタムナビゲーションバー（シンプル版）
                    WorkoutNavigationBarView(
                        exerciseName: exercise.name,
                        timerState: globalTimerViewModel.displayTimerState,
                        onDismiss: {
                            dismiss()
                        }
                    )
                    
                    // メインコンテンツ
                    ScrollView {
                        VStack(spacing: 20) {
                            // 前回・今回記録表示エリア
                            WorkoutHistorySection(
                                previousWorkout: viewModel.previousWorkout,
                                todaysSets: viewModel.todaysSets,
                                todaysVolume: viewModel.todaysVolume,
                                previousVolume: viewModel.previousVolume,
                                isLoadingHistory: viewModel.isLoadingHistory
                            )
                            
                            // 重量・回数・RPEの横並びフォーム
                            VStack(spacing: 16) {
                                Text("新しいセットを記録")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 12) {
                                    InputField(
                                        title: "重量 (kg)",
                                        text: $viewModel.weight,
                                        keyboardType: .decimalPad,
                                        focused: $focusedField,
                                        field: .weight
                                    )
                                    
                                    InputField(
                                        title: "回数",
                                        text: $viewModel.reps,
                                        keyboardType: .numberPad,
                                        focused: $focusedField,
                                        field: .reps
                                    )
                                    
                                    // RPE入力（ヘルプ付き）
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("RPE")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Button(action: {
                                                showRPEHelp = true
                                            }) {
                                                Image(systemName: "questionmark.circle")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        
                                        TextField("1〜10", text: $viewModel.rpe)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .focused($focusedField, equals: .rpe)
                                            .multilineTextAlignment(.center)
                                            .font(.title2)
                                    }
                                }
                            }
                            
                            // エラーメッセージ
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer(minLength: 100) // キーボード分の余白
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // セット登録ボタン（下部固定）
                    VStack(spacing: 12) {
                        Divider()
                        
                        Button(action: {
                            Task {
                                await viewModel.saveSet()
                                // セット登録完了後、タイマーを開始
                                if viewModel.showSuccessAlert {
                                    print("[WorkoutLogView] Set saved, starting timer - Exercise: \(exercise.name) (ID: \(exercise.id))")
                                    // セット登録時にExerciseEntityを設定
                                    globalTimerViewModel.setCurrentExercise(exercise)
                                    globalTimerViewModel.startTimer(duration: 180)
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(viewModel.isLoading ? "登録中..." : "セットを登録")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color(.systemBackground))
                }
                
                // フローティングタイマーボタン
                FloatingTimerButton(
                    timerState: globalTimerViewModel.displayTimerState,
                    onToggleTimer: {
                        print("[WorkoutLogView] Toggle timer button pressed - Exercise: \(exercise.name) (ID: \(exercise.id))")
                        // タイマー手動スタート時にExerciseEntityを設定
                        globalTimerViewModel.setCurrentExercise(exercise)
                        globalTimerViewModel.toggleTimer()
                    },
                    onResetTimer: {
                        globalTimerViewModel.resetTimer()
                    },
                    onAdjustTimer: { minutes in
                        globalTimerViewModel.adjustTimer(minutes: minutes)
                    }
                )
            }
            .navigationBarHidden(true)
            .onAppear {
                // 最初のフィールドにフォーカス
                focusedField = .weight
                print("[WorkoutLogView] View appeared - Exercise: \(exercise.name) (ID: \(exercise.id))")
                
                // 履歴を読み込み
                Task {
                    await viewModel.loadWorkoutHistory()
                }
            }
            .alert("RPE (主観的運動強度)", isPresented: $showRPEHelp) {
                Button("OK") { }
            } message: {
                Text(viewModel.rpeHelpText)
            }
            .alert("セット登録完了", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("セットが正常に登録されました")
            }
        }
    }
}

// MARK: - WorkoutHistorySection
struct WorkoutHistorySection: View {
    let previousWorkout: WorkoutHistoryEntity?
    let todaysSets: [LocalWorkoutSetEntity]
    let todaysVolume: Double
    let previousVolume: Double
    let isLoadingHistory: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // セクションタイトル
            HStack {
                Text("ワークアウト履歴")
                    .font(.headline)
                Spacer()
                if isLoadingHistory {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // 横並び固定高さエリア
            HStack(spacing: 12) {
                // 前回記録
                VStack(spacing: 0) {
                    Text("前回")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            if let previous = previousWorkout, !previous.sets.isEmpty {
                                ForEach(previous.sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                    SetRow(
                                        setNumber: set.setNumber,
                                        weight: set.weight,
                                        reps: set.reps,
                                        rpe: set.rpe,
                                        isImproved: false
                                    )
                                }
                            } else {
                                Text("記録なし")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 今日記録
                VStack(spacing: 0) {
                    Text("今日")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            if !todaysSets.isEmpty {
                                ForEach(todaysSets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                    SetRow(
                                        setNumber: Int(set.setNumber),
                                        weight: set.weight,
                                        reps: Int(set.reps),
                                        rpe: set.rpe == 0 ? nil : set.rpe,
                                        isImproved: isImprovedFromPrevious(
                                            currentSet: set,
                                            previousSets: previousWorkout?.sets ?? []
                                        )
                                    )
                                }
                            } else {
                                Text("まだセットなし")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func isImprovedFromPrevious(currentSet: LocalWorkoutSetEntity, previousSets: [WorkoutSetEntity]) -> Bool {
        // 同じセット番号の前回記録と比較
        guard let previousSet = previousSets.first(where: { $0.setNumber == currentSet.setNumber }) else {
            // 前回同じセット番号がない場合は新しいセットなので改善とみなす
            return true
        }
        
        let currentVolume = currentSet.weight * Double(currentSet.reps)
        let previousVolume = previousSet.weight * Double(previousSet.reps)
        
        return currentVolume > previousVolume
    }
}

// MARK: - SetRow Component
struct SetRow: View {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let rpe: Double?
    let isImproved: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(setNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%.1f", weight))kg × \(reps)回")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let rpe = rpe {
                    Text("RPE \(String(format: "%.1f", rpe))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isImproved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - InputField Component
struct InputField: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focused: WorkoutLogView.Field?
    let field: WorkoutLogView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("0", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .focused($focused, equals: field)
                .multilineTextAlignment(.center)
                .font(.title2)
        }
    }
}
