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
    @Published var selectedExerciseForSession: Exercise? = nil // 追加

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
        guard !isStartingSession else { return } 

        if sessionManager.isSessionActive, let existingSessionId = sessionManager.currentSessionId {
            print("AddPlaceholderViewModel: Session is already active (ID: \(existingSessionId)). Using existing session for exercise: \(exercise.name ?? exercise.canonicalName)")
            self.selectedExerciseForSession = exercise // 既存セッションでも種目情報はセット
            self.startedSessionId = existingSessionId
            self.sessionError = nil 
            self.isShowingSessionModal = true 
            return 
        }

        isStartingSession = true
        sessionError = nil
        startedSessionId = nil 
        isShowingSessionModal = false
        // selectedExerciseForSession はAPI成功後にセットする
        
        print("AddPlaceholderViewModel: Starting new session for exercise: \(exercise.name ?? exercise.canonicalName) (ID: \(exercise.id))")

        apiService.startSession(menuId: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isStartingSession = false
                switch result {
                case .success(let sessionResponse):
                    print("AddPlaceholderViewModel: New session started successfully. Session ID: \(sessionResponse.id)")
                    self.selectedExerciseForSession = exercise // API成功時に種目情報をセット
                    self.startedSessionId = sessionResponse.id
                    sessionManager.startNewSession(sessionId: sessionResponse.id)
                    self.isShowingSessionModal = true 
                case .failure(let error):
                    print("AddPlaceholderViewModel: Failed to start new session: \(error.localizedDescription)")
                    self.sessionError = error.localizedDescription
                    self.selectedExerciseForSession = nil // エラー時はクリア
                }
            }
        }
    }
}
