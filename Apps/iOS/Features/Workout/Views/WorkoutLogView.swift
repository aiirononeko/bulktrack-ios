import SwiftUI
import Domain

struct WorkoutLogView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: WorkoutLogViewModel
    @StateObject private var globalTimerViewModel: GlobalTimerViewModel
    @FocusState private var focusedField: Field?
    @State private var showRPEHelp = false
    @State private var showTimerControls = false
    @State private var setToDelete: LocalWorkoutSetEntity?
    @State private var showDeleteConfirmation = false
    
    let exercise: ExerciseEntity
    
    enum Field: CaseIterable {
        case weight, reps, rpe
    }
    
    init(
        exercise: ExerciseEntity,
        saveWorkoutSetUseCase: SaveWorkoutSetUseCaseProtocol,
        getWorkoutHistoryUseCase: GetWorkoutHistoryUseCaseProtocol,
        deleteSetUseCase: DeleteSetUseCaseProtocol,
        globalTimerViewModel: GlobalTimerViewModel
    ) {
        self.exercise = exercise
        self._viewModel = StateObject(wrappedValue: WorkoutLogViewModel(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            saveWorkoutSetUseCase: saveWorkoutSetUseCase,
            getWorkoutHistoryUseCase: getWorkoutHistoryUseCase,
            deleteSetUseCase: deleteSetUseCase
        ))
        self._globalTimerViewModel = StateObject(wrappedValue: globalTimerViewModel)
        
        print("[WorkoutLogView] Init with exercise: \(exercise.name) (ID: \(exercise.id))")
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景タップでパネルを閉じる
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showTimerControls {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showTimerControls = false
                            }
                        }
                    }
                
                VStack(spacing: 0) {
                    // カスタムナビゲーションバー（シンプル版）
                    WorkoutNavigationBarView(
                        exerciseName: exercise.name,
                        timerState: globalTimerViewModel.displayTimerState,
                        onDismiss: {
                            dismiss()
                        }
                    )
                    .padding(.bottom, 16)

                    // メインコンテンツ
                    VStack(spacing: 28) {
                        // 前回・今回記録表示エリア
                        WorkoutHistorySection(
                            previousWorkout: viewModel.previousWorkout,
                            todaysSets: viewModel.todaysSets,
                            todaysVolume: viewModel.todaysVolume,
                            previousVolume: viewModel.previousVolume,
                            isLoadingHistory: viewModel.isLoadingHistory,
                            setToDelete: $setToDelete,
                            showDeleteConfirmation: $showDeleteConfirmation
                        )
                        .onTapGesture {
                            if showTimerControls {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showTimerControls = false
                                }
                            }
                        }
                        
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
                                        .foregroundColor(Color(.label))
                                    
                                    Button(action: {
                                        showRPEHelp = true
                                    }) {
                                        Image(systemName: "questionmark.circle")
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                TextField("1〜10", text: $viewModel.rpe)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .rpe)
                                    .multilineTextAlignment(.center)
                                    .font(.title2)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                                    )
                            }
                        }
                        
                        // エラーメッセージ
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer() // 残り空間を埋める
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // 下部ボタンエリア（固定）
                    VStack(spacing: 12) {
                        // セット登録ボタンとタイマーボタン（横並び）
                        HStack(spacing: 12) {
                            // タイマーボタン
                            TimerButton(
                                timerState: globalTimerViewModel.displayTimerState,
                                onToggleTimer: {
                                    // 1タップ: タイマーの開始/停止
                                    globalTimerViewModel.setCurrentExercise(exercise)
                                    globalTimerViewModel.toggleTimer()
                                },
                                onResetTimer: {
                                    // 2タップ: タイマーのリセット
                                    globalTimerViewModel.resetTimer()
                                },
                                onShowControls: {
                                    // 長押し: 操作パネル表示
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showTimerControls.toggle()
                                    }
                                },
                                onSetDuration: { duration in
                                    // 長押しでのタイマー時間設定
                                    globalTimerViewModel.setTimerDuration(duration)
                                }
                            )

                            // セット登録ボタン
                            Button(action: {
                                Task {
                                    let previousSetCount = viewModel.todaysSetCount
                                    await viewModel.saveSet()
                                    // セット登録完了後、タイマーを開始（セット数が増加した場合のみ）
                                    if viewModel.todaysSetCount > previousSetCount {
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
                                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(viewModel.isLoading ? "登録中..." : "セットを登録")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(colorScheme == .dark ? .white : .black)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                    .background(Color(.systemBackground))
                }
                
                // タイマー操作パネル（オーバーレイとして独立配置）
                if showTimerControls {
                    VStack {
                        Spacer()
                        
                        // ボタンエリアの上にパネルを左寄せで配置
                        HStack {
                            TimerControlPanel(
                                timerState: globalTimerViewModel.displayTimerState,
                                onAdjustTimer: { minutes in
                                    globalTimerViewModel.adjustTimer(minutes: minutes)
                                },
                                onClose: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showTimerControls = false
                                    }
                                }
                            )
                            
                            Spacer()
                        }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80) // ボタンエリアの高さ分上にオフセット
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // 最初のフィールドにフォーカス
                focusedField = .weight
                print("[WorkoutLogView] View appeared - Exercise: \(exercise.name) (ID: \(exercise.id))")
                
                // WorkoutLogView専用：タイマー完了時の自動リセットを有効化
                globalTimerViewModel.setCurrentExercise(exercise, enableAutoReset: true)
                globalTimerViewModel.enableAutoResetMode()
                
                // 既に完了しているタイマーがある場合は即座にリセット
                if let currentTimer = globalTimerViewModel.timerState, 
                   currentTimer.status == .completed {
                    print("[WorkoutLogView] Timer already completed - resetting immediately")
                    globalTimerViewModel.resetTimer()
                }
                
                // 履歴を読み込み
                Task {
                    await viewModel.loadWorkoutHistory()
                }
            }
            .onDisappear {
                // WorkoutLogViewを離れる時は自動リセットモードを無効化
                globalTimerViewModel.disableAutoResetMode()
                print("[WorkoutLogView] View disappeared - Auto-reset mode disabled")
            }
            .alert("RPE (主観的運動強度)", isPresented: $showRPEHelp) {
                Button("OK") { }
            } message: {
                Text(viewModel.rpeHelpText)
            }
            .toast(manager: viewModel.toastManager)
            .alert("セットを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {
                    setToDelete = nil
                }
                Button("削除", role: .destructive) {
                    if let set = setToDelete {
                        Task {
                            await viewModel.deleteSet(set)
                            setToDelete = nil
                        }
                    }
                }
            } message: {
                if let set = setToDelete {
                    Text("セット\(set.setNumber)（\(String(format: "%.1f", set.weight))kg × \(set.reps)回）を削除しますか？")
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
    @Binding var setToDelete: LocalWorkoutSetEntity?
    @Binding var showDeleteConfirmation: Bool
    
    var body: some View {
        VStack {
            // 横並び固定高さエリア
            HStack(spacing: 12) {
                // 前回記録
                VStack(spacing: 0) {
                    Text("前回のトレーニング")
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
                    Text("今日のトレーニング")
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
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        setToDelete = set
                                        showDeleteConfirmation = true
                                    }
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
                    .foregroundColor(Color(.label))
                
                if let rpe = rpe {
                    Text("RPE \(String(format: "%.1f", rpe))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isImproved {
                Image(systemName: "arrow.up.right")
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(.label))
            
            TextField("0", text: $text)
                .keyboardType(keyboardType)
                .focused($focused, equals: field)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? .white : .black
    }
}
