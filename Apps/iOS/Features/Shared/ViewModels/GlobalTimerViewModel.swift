import SwiftUI
import Combine
import Domain

/// グローバルタイマーのプロキシViewModel
/// アプリ全体で単一のタイマー状態を共有するための軽量なプロキシ
@MainActor
final class GlobalTimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var timerState: TimerState?
    @Published var isTimerActive: Bool = false
    @Published var shouldNavigateToExercise: ExerciseEntity?
    @Published var onTimerCompleted: (() -> Void)?
    
    // MARK: - Private Properties
    private let globalTimerService: GlobalTimerServiceProtocol
    private let exerciseRepository: ExerciseRepository
    private let timerSettingsService: TimerSettingsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentExerciseId: UUID?
    private var currentExercise: ExerciseEntity?
    private let instanceId = UUID().uuidString.prefix(8) // インスタンス識別用
    
    // WorkoutLogView からのタイマー完了自動リセット制御
    private var shouldAutoResetOnCompletion = false
    
    // タイマー完了時のコールバック
    private var timerCompletionCallback: (() -> Void)?
    
    // 元のタイマー時間を保存（リセット時に使用）
    private var originalTimerDuration: TimeInterval {
        timerSettingsService.defaultTimerDuration
    }
    
    // MARK: - Computed Properties
    var hasActiveTimer: Bool {
        guard let timer = timerState else { return false }
        // 完了状態で表示継続が有効な場合も含める
        if timer.status == .completed && timer.shouldPersistAfterCompletion {
            return true
        }
        return timer.status == .running || timer.status == .paused
    }
    
    var displayTimerState: TimerState {
        timerState ?? .defaultTimer()
    }
    
    // MARK: - Initialization
    init(
        globalTimerService: GlobalTimerServiceProtocol,
        exerciseRepository: ExerciseRepository,
        timerSettingsService: TimerSettingsServiceProtocol
    ) {
        self.globalTimerService = globalTimerService
        self.exerciseRepository = exerciseRepository
        self.timerSettingsService = timerSettingsService
        
        print("[GlobalTimerViewModel-\(instanceId)] Instance created")
        setupObservation()
    }
    
    deinit {
        print("[GlobalTimerViewModel-\(instanceId)] Instance deallocated")
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Public Methods
extension GlobalTimerViewModel {
    /// 現在のExerciseEntityを設定（画面遷移時に呼び出し）
    /// - Parameters:
    ///   - exercise: 現在の種目のExerciseEntity
    ///   - enableAutoReset: タイマー完了時の自動リセットを有効にするか（WorkoutLogViewでのみtrue）
    func setCurrentExercise(_ exercise: ExerciseEntity, enableAutoReset: Bool = false) {
        currentExercise = exercise
        currentExerciseId = exercise.id
        shouldAutoResetOnCompletion = enableAutoReset
        print("[GlobalTimerViewModel-\(instanceId)] Exercise context set: \(exercise.name) (ID: \(exercise.id)), autoReset: \(enableAutoReset)")
    }
    
    /// WorkoutLogView専用：自動リセットモードを有効化
    /// - Parameter onTimerCompleted: タイマー完了時に実行するコールバック（トースト表示など）
    func enableAutoResetMode(onTimerCompleted: (() -> Void)? = nil) {
        shouldAutoResetOnCompletion = true
        timerCompletionCallback = onTimerCompleted
        print("[GlobalTimerViewModel-\(instanceId)] Auto-reset mode enabled for WorkoutLogView")
        
        // 既に完了しているタイマーがあれば即座にリセット
        if let currentTimer = timerState, currentTimer.status == .completed {
            print("[GlobalTimerViewModel-\(instanceId)] Found completed timer when enabling auto-reset - resetting immediately")
            DispatchQueue.main.async { [weak self] in
                self?.resetTimer()
            }
        }
    }
    
    /// WorkoutLogView専用：自動リセットモードを無効化
    func disableAutoResetMode() {
        shouldAutoResetOnCompletion = false
        timerCompletionCallback = nil
        print("[GlobalTimerViewModel-\(instanceId)] Auto-reset mode disabled")
    }
    
    /// グローバルタイマーを開始
    /// - Parameters:
    ///   - duration: タイマー時間（秒）
    ///   - exerciseId: 関連する種目ID（オプション、設定されていればcurrentExerciseIdを使用）
    ///   - exercise: 関連するエクササイズエンティティ（オプション、設定されていればcurrentExerciseを使用）
    func startTimer(duration: TimeInterval, exerciseId: UUID? = nil, exercise: ExerciseEntity? = nil) {
        // 引数で渡された値があれば更新、なければ既存の値を使用
        if let exerciseId = exerciseId {
            currentExerciseId = exerciseId
        }
        if let exercise = exercise {
            currentExercise = exercise
        }
        
        // Note: originalTimerDuration は computed property として timerSettingsService.defaultTimerDuration を返すように変更済み
        
        let finalExerciseId = currentExerciseId ?? UUID()
        let exerciseName = currentExercise?.name
        
        print("[GlobalTimerViewModel-\(instanceId)] Starting timer for exercise: \(exerciseName ?? "Unknown") (ID: \(finalExerciseId))")
        print("[GlobalTimerViewModel-\(instanceId)] Cached exercise: \(currentExercise != nil ? "YES" : "NO")")
        print("[GlobalTimerViewModel-\(instanceId)] Original timer duration saved: \(originalTimerDuration)s")
        
        // Live Activity対応：種目名も渡す
        globalTimerService.startGlobalTimer(duration: duration, exerciseId: finalExerciseId, exerciseName: exerciseName)
    }
    
    /// グローバルタイマーを一時停止
    func pauseTimer() {
        globalTimerService.pauseGlobalTimer()
    }
    
    /// グローバルタイマーを再開
    func resumeTimer() {
        globalTimerService.resumeGlobalTimer()
    }
    
    /// グローバルタイマーをリセット
    func resetTimer() {
        globalTimerService.clearGlobalTimer()
        print("[GlobalTimerViewModel-\(instanceId)] Timer reset, exercise context preserved: \(currentExercise?.name ?? "nil")")
    }
    
    /// 元のタイマー時間でリセット
    private func resetTimerToOriginalDuration() {
        globalTimerService.clearGlobalTimerWithDuration(originalTimerDuration)
        print("[GlobalTimerViewModel-\(instanceId)] Timer reset to original duration: \(originalTimerDuration)s")
    }
    
    /// タイマー時間を調整
    /// - Parameter minutes: 調整する分数（正数で増加、負数で減少）
    func adjustTimer(minutes: Int) {
        globalTimerService.adjustGlobalTimer(minutes: minutes)
    }
    
    /// タイマー時間を設定
    /// - Parameter duration: 新しいタイマー時間（秒）
    func setTimerDuration(_ duration: Int) {
        let timeInterval = TimeInterval(duration)
        timerSettingsService.setDefaultTimerDuration(timeInterval)
        globalTimerService.setTimerDuration(timeInterval)
        print("[GlobalTimerViewModel-\(instanceId)] Timer duration set and saved: \(timeInterval)s")
    }
    
    /// タイマーボタンがタップされた時のアクション
    func onTimerButtonTapped() {
        // タイマーをタップした場合、エクササイズ画面に遷移
        if hasActiveTimer {
            navigateToExercise()
        }
    }
    
    /// エクササイズ画面に戻る
    func navigateToExercise() {
        print("[GlobalTimerViewModel-\(instanceId)] Navigate to exercise requested")
        print("[GlobalTimerViewModel-\(instanceId)] Current exercise cached: \(currentExercise != nil)")
        print("[GlobalTimerViewModel-\(instanceId)] Current exercise ID: \(currentExerciseId?.uuidString ?? "nil")")
        
        // キャッシュされたエクササイズがある場合はそれを直接使用（API呼び出し不要）
        if let cachedExercise = currentExercise {
            print("[GlobalTimerViewModel-\(instanceId)] Using cached exercise: \(cachedExercise.name)")
            shouldNavigateToExercise = cachedExercise
            return
        }
        
        // ExerciseEntityがない場合はエラーログ（本来起こるべきではない）
        print("[GlobalTimerViewModel-\(instanceId)] ERROR: No cached exercise found, navigation failed")
    }
    
    /// タイマーの切り替え（開始/停止）
    func toggleTimer() {
        guard let currentState = timerState else {
            // タイマーがない場合は新しく開始（currentExerciseを使用）
            startTimer(duration: originalTimerDuration)
            return
        }
        
        switch currentState.status {
        case .idle, .completed:
            // アイドル・完了状態からは再開 or 新しく開始
            if currentState.status == .completed {
                // 完了状態からは新しく開始
                startTimer(duration: originalTimerDuration)
            } else {
                // アイドル状態からは再開（Live Activity対応で種目名も渡す）
                let exerciseId = currentExerciseId ?? UUID()
                let exerciseName = currentExercise?.name
                globalTimerService.startGlobalTimer(duration: currentState.duration, exerciseId: exerciseId, exerciseName: exerciseName)
            }
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        }
    }
}

// MARK: - Private Methods
private extension GlobalTimerViewModel {
    func setupObservation() {
        globalTimerService.currentTimer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTimerState in
                self?.handleTimerStateUpdate(newTimerState)
            }
            .store(in: &cancellables)
    }
    
    func handleTimerStateUpdate(_ newTimerState: TimerState?) {
        let previousState = timerState
        timerState = newTimerState
        isTimerActive = globalTimerService.isTimerActive
        
        // exerciseIdを記録（ただし、既存のcurrentExerciseIdがない場合のみ）
        if let state = newTimerState, let exerciseId = state.exerciseId, currentExerciseId == nil {
            currentExerciseId = exerciseId
        }
        
        // Note: originalTimerDuration は computed property として timerSettingsService.defaultTimerDuration を返すため、設定不要
        
        // タイマー完了時の処理
        if let newState = newTimerState, newState.status == .completed {
            // 実行中から完了になった場合のみ完了処理を実行
            if let prevState = previousState, prevState.status == .running {
                // タイマー完了コールバックを実行（トースト表示など）
                timerCompletionCallback?()
                print("[GlobalTimerViewModel-\(instanceId)] Timer completed - executed completion callback")
            }
            
            if shouldAutoResetOnCompletion {
                // WorkoutLogViewでは自動リセット
                // 実行中から完了になった場合は遅延リセット、既に完了している場合は即座にリセット
                if let prevState = previousState, prevState.status == .running {
                    print("[GlobalTimerViewModel-\(instanceId)] Timer completed in WorkoutLogView - scheduling auto-reset")
                    
                    // 3秒後に自動リセット（ユーザーが完了を確認できる時間を確保）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                        guard let self = self, self.shouldAutoResetOnCompletion else { return }
                        print("[GlobalTimerViewModel-\(instanceId)] Auto-resetting timer in WorkoutLogView (delayed) to \(self.originalTimerDuration)s")
                        self.resetTimerToOriginalDuration()
                    }
                } else {
                    // 既に完了している状態でWorkoutLogViewに入った場合は即座にリセット
                    print("[GlobalTimerViewModel-\(instanceId)] Timer already completed in WorkoutLogView - resetting immediately to \(originalTimerDuration)s")
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, self.shouldAutoResetOnCompletion else { return }
                        self.resetTimerToOriginalDuration()
                    }
                }
            } else {
                // 他のページではタイマー完了ステータスを維持
                print("[GlobalTimerViewModel-\(instanceId)] Timer completed - maintaining completed status for navigation")
            }
        }
        
        if let state = newTimerState {
            print("[GlobalTimerViewModel-\(instanceId)] Timer state updated: \(state.status), remaining: \(state.formattedRemainingTime), shouldPersist: \(state.shouldPersistAfterCompletion), autoReset: \(shouldAutoResetOnCompletion), originalDuration: \(originalTimerDuration)s")
        } else {
            print("[GlobalTimerViewModel-\(instanceId)] Timer cleared")
        }
    }
}

// MARK: - UI State Helpers
extension GlobalTimerViewModel {
    /// タイマーボタンのテキスト
    var timerButtonText: String {
        guard let timer = timerState else { return "タイマー" }
        
        switch timer.status {
        case .idle:
            return "開始"
        case .running:
            return "一時停止"
        case .paused:
            return "再開"
        case .completed:
            return "リセット"
        }
    }
}
