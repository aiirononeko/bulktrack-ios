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
}
