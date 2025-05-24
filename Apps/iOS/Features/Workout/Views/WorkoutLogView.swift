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
    
    init(exercise: ExerciseEntity, createSetUseCase: CreateSetUseCaseProtocol, globalTimerViewModel: GlobalTimerViewModel) {
        self.exercise = exercise
        self._viewModel = StateObject(wrappedValue: WorkoutLogViewModel(exerciseId: exercise.id, createSetUseCase: createSetUseCase))
        self._globalTimerViewModel = StateObject(wrappedValue: globalTimerViewModel)
        
        print("[WorkoutLogView] Init with exercise: \(exercise.name) (ID: \(exercise.id))")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タイマーバナー（上部固定）
                TimerBannerView(
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
                
                // メイン入力フォーム
                ScrollView {
                    VStack(spacing: 24) {
                        // 重量・回数・RPEの横並びフォーム
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
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                // 最初のフィールドにフォーカス
                focusedField = .weight
                print("[WorkoutLogView] View appeared - Exercise: \(exercise.name) (ID: \(exercise.id))")
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
