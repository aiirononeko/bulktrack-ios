import Foundation

public protocol FetchAllExercisesUseCaseProtocol {
    func execute(limit: Int, offset: Int, query: String?, locale: String?) async throws -> [ExerciseEntity]
}

public final class FetchAllExercisesUseCase: FetchAllExercisesUseCaseProtocol {
    private let exerciseRepository: ExerciseRepository

    public init(exerciseRepository: ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }

    public func execute(limit: Int, offset: Int, query: String?, locale: String?) async throws -> [ExerciseEntity] {
        do {
            // query に nil を渡すことで全件検索を意図する
            return try await exerciseRepository.searchExercises(query: query, locale: locale)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknownError(error.localizedDescription)
        }
    }
}
