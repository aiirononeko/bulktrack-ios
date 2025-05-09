import Foundation
import SwiftUI // ObservableObjectのために必要

final class AppInitializer: ObservableObject {
    private let activationService = ActivationService()
    private let apiService = APIService()

    // アプリの初期化処理を実行
    func initializeApp() {
        print("AppInitializer: Initializing app...")
        activationService.activateDeviceIfNeeded { [weak self] result in // selfへの弱参照を使用
            guard let self = self else { return } // selfがnilの場合は何もしない
            
            // DispatchQueue.main.async を使ってメインスレッドで実行
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("AppInitializer: Activation process completed (or not needed).")
                    self.testFetchExercises()
                case .failure(let error):
                    print("AppInitializer: Activation process failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func testFetchExercises() {
        print("AppInitializer: Testing fetchExercises...")
        apiService.fetchExercises(query: nil, locale: "ja") { result in
            // DispatchQueue.main.async を使ってUI更新の可能性がある処理をメインスレッドで実行
            DispatchQueue.main.async {
                switch result {
                case .success(let exercises):
                    print("AppInitializer: Successfully fetched \(exercises.count) exercises.")
                    if let firstExercise = exercises.first {
                        print("AppInitializer: First exercise: \(firstExercise.name ?? firstExercise.canonicalName)")
                    }
                case .failure(let error):
                    print("AppInitializer: Failed to fetch exercises: \(error.localizedDescription)")
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            print("AppInitializer: Error details: Unauthorized - token might be invalid or expired.")
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
}
