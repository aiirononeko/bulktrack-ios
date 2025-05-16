import Foundation
import SwiftUI

// AddPlaceholderViewModel クラスの定義を先に
final class AddPlaceholderViewModel: ObservableObject {
    // ネストされた Exercise 構造体の定義を削除
    // (APIService.swift で定義されているグローバルな Exercise モデルを使用する)

    private let apiService = APIService() // APIService.swift がプロジェクトに存在すると仮定

    @Published var recentExercises: [Exercise] = [] // 最近の種目
    @Published var searchedExercises: [Exercise] = [] // グローバルな Exercise モデルの配列
    @Published var isLoadingRecent: Bool = false
    @Published var isLoadingSearch: Bool = false
    @Published var errorMessage: String?

    // セッション開始用に追加
    @Published var startedSessionId: String? = nil
    @Published var isShowingSessionModal: Bool = false
    @Published var isStartingSession: Bool = false // セッション開始処理中のローディング状態
    @Published var sessionError: String? = nil   // セッション開始時のエラーメッセージ
    @Published var selectedExerciseForSession: Exercise? = nil // 追加

    func fetchRecentExercisesOnAppear() {
        isLoadingRecent = true
        errorMessage = nil
        print("AddPlaceholderViewModel: Fetching recent exercises...")

        apiService.fetchRecentExercises { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingRecent = false
                switch result {
                case .success(let fetchedExercises):
                    self.recentExercises = fetchedExercises
                    print("AddPlaceholderViewModel: Successfully fetched \(self.recentExercises.count) recent exercises.")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("AddPlaceholderViewModel: Failed to fetch recent exercises: \(error.localizedDescription)")
                    if let apiError = error as? APIError, case .unauthorized = apiError {
                         print("AddPlaceholderViewModel: Error details: Unauthorized for recent exercises.")
                    }
                }
            }
        }
    }

    func searchExercises(query: String?) {
        isLoadingSearch = true
        errorMessage = nil
        print("AddPlaceholderViewModel: Searching exercises with query: \(query ?? "nil")...")

        // クエリが空の場合は検索結果をクリアして何もしない（または最近の種目を表示するUI側で制御）
        guard let searchQuery = query, !searchQuery.isEmpty else {
            self.searchedExercises = []
            self.isLoadingSearch = false
            print("AddPlaceholderViewModel: Search query is empty, cleared searched exercises.")
            return
        }
        
        apiService.fetchExercises(query: searchQuery, locale: "ja") { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingSearch = false
                switch result {
                case .success(let fetchedExercises):
                    self.searchedExercises = fetchedExercises
                    print("AddPlaceholderViewModel: Successfully fetched \(self.searchedExercises.count) exercises for query '\(searchQuery)'.")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    // 検索結果はクリアしておくのが良いか、エラーメッセージ次第
                    self.searchedExercises = []
                    print("AddPlaceholderViewModel: Failed to fetch exercises for query '\(searchQuery)': \(error.localizedDescription)")
                    if let apiError = error as? APIError, case .unauthorized = apiError {
                         print("AddPlaceholderViewModel: Error details: Unauthorized for exercises search.")
                    }
                }
            }
        }
    }

    func selectExerciseAndStartSession(exercise: Exercise, sessionManager: SessionManager) {
        sessionError = nil
        
        // サーバーセッションIDの代わりにローカルでユニークなIDを生成 (またはSessionManagerに生成させる)
        // SessionWorkoutViewがこのIDを「今回のトレーニングの区切り」として使うことを想定
        let localWorkoutGroupId = UUID().uuidString 
        self.startedSessionId = localWorkoutGroupId
        self.selectedExerciseForSession = exercise
        
        // SessionManagerのメソッドも新しい名前に合わせる (sessionId引数なし)
        sessionManager.startNewWorkoutGrouping()
        
        self.isShowingSessionModal = true 
        print("AddPlaceholderViewModel: Starting new workout view for exercise: \(exercise.name ?? exercise.canonicalName) with local group ID: \(localWorkoutGroupId)")

        // apiService.startSession(menuId: nil) { ... } // API呼び出し削除
    }
}
