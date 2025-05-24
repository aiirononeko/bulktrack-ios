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
    
    // MARK: - Private Properties
    private let globalTimerService: GlobalTimerServiceProtocol
    private let exerciseRepository: ExerciseRepository
    private var cancellables = Set<AnyCancellable>()
    private var currentExerciseId: UUID?
    private var currentExercise: ExerciseEntity?
    private let instanceId = UUID().uuidString.prefix(8) // インスタンス識別用
    
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
        exerciseRepository: ExerciseRepository
    ) {
        self.globalTimerService = globalTimerService
        self.exerciseRepository = exerciseRepository
        
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
    /// - Parameter exercise: 現在の種目のExerciseEntity
    func setCurrentExercise(_ exercise: ExerciseEntity) {
        currentExercise = exercise
        currentExerciseId = exercise.id
        print("[GlobalTimerViewModel-\(instanceId)] Exercise context set: \(exercise.name) (ID: \(exercise.id))")
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
        
        let finalExerciseId = currentExerciseId ?? UUID()
        let exerciseName = currentExercise?.name ?? "Unknown"
        
        print("[GlobalTimerViewModel-\(instanceId)] Starting timer for exercise: \(exerciseName) (ID: \(finalExerciseId))")
        print("[GlobalTimerViewModel-\(instanceId)] Cached exercise: \(currentExercise != nil ? "YES" : "NO")")
        
        globalTimerService.startGlobalTimer(duration: duration, exerciseId: finalExerciseId)
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
    
    /// タイマー時間を調整
    /// - Parameter minutes: 調整する分数（正数で増加、負数で減少）
    func adjustTimer(minutes: Int) {
        globalTimerService.adjustGlobalTimer(minutes: minutes)
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
            startTimer(duration: 180)
            return
        }
        
        switch currentState.status {
        case .idle, .completed:
            // アイドル・完了状態からは再開 or 新しく開始
            if currentState.status == .completed {
                // 完了状態からは新しく開始
                startTimer(duration: 180)
            } else {
                // アイドル状態からは再開
                let exerciseId = currentExerciseId ?? UUID()
                globalTimerService.startGlobalTimer(duration: currentState.duration, exerciseId: exerciseId)
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
        timerState = newTimerState
        isTimerActive = globalTimerService.isTimerActive
        
        // exerciseIdを記録（ただし、既存のcurrentExerciseIdがない場合のみ）
        if let state = newTimerState, let exerciseId = state.exerciseId, currentExerciseId == nil {
            currentExerciseId = exerciseId
        }
        
        if let state = newTimerState {
            print("[GlobalTimerViewModel-\(instanceId)] Timer state updated: \(state.status), remaining: \(state.formattedRemainingTime), shouldPersist: \(state.shouldPersistAfterCompletion)")
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
