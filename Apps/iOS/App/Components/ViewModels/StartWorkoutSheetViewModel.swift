import Foundation
import Domain

@MainActor
class StartWorkoutSheetViewModel: ObservableObject {
    // Recent Exercises
    @Published var recentExercises: [ExerciseEntity] = []
    @Published var isLoadingRecent: Bool = false
    @Published var errorMessageRecent: String?

    // All Exercises
    @Published var allExercises: [ExerciseEntity] = []
    @Published var isLoadingAll: Bool = false
    @Published var errorMessageAll: String?

    private let fetchRecentExercisesUseCase: FetchRecentExercisesUseCaseProtocol
    private let fetchAllExercisesUseCase: FetchAllExercisesUseCaseProtocol // Added

    // TODO: locale は適切に設定する必要がある
    private let defaultLocale = "ja_JP" // 仮のロケール
    private let defaultLimit = 20 // 仮の取得件数
    private let defaultOffset = 0 // 仮のオフセット

    init(
        fetchRecentExercisesUseCase: FetchRecentExercisesUseCaseProtocol,
        fetchAllExercisesUseCase: FetchAllExercisesUseCaseProtocol // Added
    ) {
        self.fetchRecentExercisesUseCase = fetchRecentExercisesUseCase
        self.fetchAllExercisesUseCase = fetchAllExercisesUseCase // Added
    }

    func loadRecentExercises() {
        isLoadingRecent = true
        errorMessageRecent = nil

        Task {
            do {
                let exercises = try await fetchRecentExercisesUseCase.execute(
                    limit: defaultLimit,
                    offset: defaultOffset,
                    locale: defaultLocale
                )
                self.recentExercises = exercises
            } catch let error as AppError {
                self.errorMessageRecent = error.localizedDescription
            } catch {
                self.errorMessageRecent = error.localizedDescription
            }
            self.isLoadingRecent = false
        }
    }

    func loadAllExercises() {
        isLoadingAll = true
        errorMessageAll = nil

        Task {
            do {
                // query: nil で全件取得を意図
                let exercises = try await fetchAllExercisesUseCase.execute(
                    limit: defaultLimit, // 必要に応じて調整
                    offset: defaultOffset, // 必要に応じて調整
                    query: nil,
                    locale: defaultLocale
                )
                self.allExercises = exercises
            } catch let error as AppError {
                self.errorMessageAll = error.localizedDescription
            } catch {
                self.errorMessageAll = error.localizedDescription
            }
            self.isLoadingAll = false
        }
    }
}
