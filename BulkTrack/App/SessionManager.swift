import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published var currentSessionId: String? = nil
    @Published var isEndingSession: Bool = false
    @Published var sessionEndingError: String? = nil
    // isSessionActive は currentSessionId の有無で決定できるので、コンピューテッドプロパティでも良い
    // @Published var isSessionActive: Bool = false 
    // または、より明示的に状態を管理したい場合は @Published のままにする

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
            // self.isSessionActive = true (もし Published なら)
            print("SessionManager: New session started with ID: \(sessionId)")
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
