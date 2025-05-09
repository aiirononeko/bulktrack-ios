import Foundation
import Combine

// APIService.swift などで定義されている WorkoutSetResponse をここで参照できるようにする必要がある
// import するか、このファイル内に WorkoutSetResponse の定義を移動・コピーする
// (ただし、モデル定義は一箇所にまとめるのが理想)
// この例では、WorkoutSetResponse がグローバルにアクセス可能であると仮定しています。

class SessionManager: ObservableObject {
    @Published var currentSessionId: String? = nil
    @Published var isEndingSession: Bool = false
    @Published var sessionEndingError: String? = nil
    // isSessionActive は currentSessionId の有無で決定できるので、コンピューテッドプロパティでも良い
    // @Published var isSessionActive: Bool = false 
    // または、より明示的に状態を管理したい場合は @Published のままにする

    // 新しく追加: 種目ごとの記録済みセットを保持 (現在のセッションに紐づく)
    @Published var recordedSetsForCurrentSession: [String: [WorkoutSetResponse]] = [:]

    var isSessionActive: Bool {
        currentSessionId != nil
    }

    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService()

    init() {
        // currentSessionId の変更を監視して isSessionActive を更新する (もし isSessionActive を Published にする場合)
        /*
        $currentSessionId
            .map { $0 != nil }
            .assign(to: \.isSessionActive, on: self)
            .store(in: &cancellables)
        */
        
        // UserDefaults から前回のセッション情報を読み込む (オプション)
        // loadSessionFromUserDefaults()
        print("SessionManager initialized. Current Session ID: \(currentSessionId ?? "None")")
    }

    func startNewSession(sessionId: String) {
        DispatchQueue.main.async {
            self.currentSessionId = sessionId
            self.recordedSetsForCurrentSession = [:] // 新しいセッションでセット記録をクリア
            self.sessionEndingError = nil // エラー状態もリセット
            self.isEndingSession = false // ローディング状態もリセット
            print("SessionManager: New session started with ID: \(sessionId). Recorded sets cleared.")
            // UserDefaults に保存 (オプション)
            // self.saveSessionToUserDefaults()
        }
    }

    func endCurrentSession() {
        guard let sessionIdToFinish = currentSessionId, !isEndingSession else {
            print("SessionManager: No active session to end or already ending a session.")
            if isEndingSession {
                 print("SessionManager: Already processing an end session request.")
            }
            if currentSessionId == nil {
                print("SessionManager: currentSessionId is nil, cannot end.")
            }
            return
        }

        print("SessionManager: Attempting to end session ID: \(sessionIdToFinish)")
        isEndingSession = true
        sessionEndingError = nil

        apiService.finishSession(sessionId: sessionIdToFinish) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isEndingSession = false
                switch result {
                case .success:
                    print("SessionManager: Successfully ended session ID: \(sessionIdToFinish) via API.")
                    self.currentSessionId = nil
                    self.recordedSetsForCurrentSession = [:] // セッション終了時にセット記録をクリア
                    print("SessionManager: Recorded sets cleared after session end.")
                case .failure(let error):
                    print("SessionManager: Failed to end session ID: \(sessionIdToFinish) via API. Error: \(error.localizedDescription)")
                    self.sessionEndingError = error.localizedDescription
                    // 必要に応じて、ここで currentSessionId を nil にしないポリシーも検討できる
                    // (例: APIエラーでもローカルの状態は終了扱いにするか、エラーをユーザーに通知してリトライを促すか)
                    // 今回はAPI失敗時はローカルセッションIDを維持する
                }
            }
        }
    }

    // 新しく追加: 指定された種目の記録済みセットを取得する
    func getRecordedSets(for exerciseId: String) -> [WorkoutSetResponse] {
        return recordedSetsForCurrentSession[exerciseId] ?? []
    }

    // 新しく追加: 新しいセットを記録に追加する
    func addRecordedSet(_ setResponse: WorkoutSetResponse, for exerciseId: String) {
        var setsForExercise = self.recordedSetsForCurrentSession[exerciseId] ?? []
        setsForExercise.append(setResponse)
        self.recordedSetsForCurrentSession[exerciseId] = setsForExercise
        print("SessionManager: Added set for exercise \(exerciseId). Total sets now: \(setsForExercise.count) for this session.")
    }
    
    // 新しく追加: 全てのセッション関連データをクリアする（オプション）
    func clearAllSessionData() {
        DispatchQueue.main.async {
            self.currentSessionId = nil
            self.recordedSetsForCurrentSession = [:]
            self.sessionEndingError = nil
            self.isEndingSession = false
            print("SessionManager: All session data (ID and recorded sets) cleared.")
        }
    }

    // --- UserDefaults Persistence (Optional) ---
    /*
    private let sessionIdKey = "app.bulktrack.currentSessionId"

    private func saveSessionToUserDefaults() {
        UserDefaults.standard.set(currentSessionId, forKey: sessionIdKey)
    }

    private func loadSessionFromUserDefaults() {
        if let savedSessionId = UserDefaults.standard.string(forKey: sessionIdKey) {
            self.currentSessionId = savedSessionId
            // self.isSessionActive = true (もし Published なら)
            print("SessionManager: Loaded session from UserDefaults: \(savedSessionId)")
        } else {
            print("SessionManager: No session found in UserDefaults.")
        }
    }

    private func clearSessionFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: sessionIdKey)
        print("SessionManager: Cleared session from UserDefaults.")
    }
    */
}
