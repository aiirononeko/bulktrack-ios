import Foundation
import SwiftUI

// AddPlaceholderViewModel クラスの定義を先に
final class AddPlaceholderViewModel: ObservableObject {
    // ネストされた Exercise 構造体の定義を削除
    // (APIService.swift で定義されているグローバルな Exercise モデルを使用する)

    private let apiService = APIService() // APIService.swift がプロジェクトに存在すると仮定

    @Published var exercises: [Exercise] = [] // グローバルな Exercise モデルの配列
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // セッション開始用に追加
    @Published var startedSessionId: String? = nil
    @Published var isShowingSessionModal: Bool = false
    @Published var isStartingSession: Bool = false // セッション開始処理中のローディング状態
    @Published var sessionError: String? = nil   // セッション開始時のエラーメッセージ

    func fetchExercises() {
        isLoading = true
        errorMessage = nil
        print("AddPlaceholderViewModel: Fetching exercises...")

        apiService.fetchExercises(query: nil, locale: "ja") { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let fetchedExercises): // fetchedExercises は APIService.Exercise の配列のはず
                    // 型変換は不要になったので直接代入
                    self.exercises = fetchedExercises 
                    print("AddPlaceholderViewModel: Successfully fetched \(self.exercises.count) exercises.")
                    if let firstExercise = self.exercises.first {
                        // APIService.Exercise の isOfficial は Bool? なので注意
                        print("First exercise (APIService.Exercise model): \(firstExercise.name ?? firstExercise.canonicalName), isOfficial: \(String(describing: firstExercise.isOfficial)) ")
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("AddPlaceholderViewModel: Failed to fetch exercises: \(error.localizedDescription)")
                    if let apiError = error as? APIError, case .unauthorized = apiError {
                         print("AddPlaceholderViewModel: Error details: Unauthorized for exercises.")
                    }
                }
            }
        }
    }

    func selectExerciseAndStartSession(exercise: Exercise, sessionManager: SessionManager) {
        guard !isStartingSession else { return } // 重複実行を防ぐ
        
        // もし既にセッションがアクティブなら、新しいセッションを開始せず既存のセッション情報を利用する
        if sessionManager.isSessionActive, let existingSessionId = sessionManager.currentSessionId {
            print("AddPlaceholderViewModel: Session is already active (ID: \(existingSessionId)). Using existing session.")
            self.startedSessionId = existingSessionId
            self.sessionError = nil // 既存セッションを使うのでエラーはクリア
            self.isShowingSessionModal = true // モーダルを表示
            // isStartingSession は false のまま (API呼び出しをしないため)
            return // API呼び出しをスキップして終了
        }

        // アクティブなセッションがない場合、新しいセッションを開始する
        isStartingSession = true
        sessionError = nil
        startedSessionId = nil // 新しいセッションIDを待つので一旦nilに
        isShowingSessionModal = false // API成功後にtrueにする
        
        print("AddPlaceholderViewModel: Starting new session for exercise: \(exercise.name ?? exercise.canonicalName) (ID: \(exercise.id))")

        // 種目選択からのセッション開始なので menuId は nil
        apiService.startSession(menuId: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isStartingSession = false
                switch result {
                case .success(let sessionResponse):
                    print("AddPlaceholderViewModel: New session started successfully. Session ID: \(sessionResponse.id)")
                    self.startedSessionId = sessionResponse.id
                    // SessionManager の状態を更新
                    sessionManager.startNewSession(sessionId: sessionResponse.id)
                    self.isShowingSessionModal = true // セッションID取得成功後にモーダル表示
                case .failure(let error):
                    print("AddPlaceholderViewModel: Failed to start new session: \(error.localizedDescription)")
                    self.sessionError = error.localizedDescription
                }
            }
        }
    }
}
