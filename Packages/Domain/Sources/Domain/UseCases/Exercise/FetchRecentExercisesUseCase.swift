import Foundation
// Combine は不要になる

public protocol FetchRecentExercisesUseCaseProtocol {
    // async throws に変更
    func execute(limit: Int, offset: Int, locale: String?) async throws -> [ExerciseEntity]
}

public final class FetchRecentExercisesUseCase: FetchRecentExercisesUseCaseProtocol {
    private let exerciseRepository: ExerciseRepository

    public init(exerciseRepository: ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }

    // async throws に変更
    public func execute(limit: Int, offset: Int, locale: String?) async throws -> [ExerciseEntity] {
        do {
            // APIService (@MainActor) のメソッドを呼び出す
            // UseCase 自体は @MainActor でなくても、呼び出し元の ViewModel が @MainActor であれば
            // repository のメソッド呼び出しは適切にディスパッチされるはず。
            // もし repository が @MainActor で保護されているなら、この呼び出しはメインスレッドで行われる。
            return try await exerciseRepository.recentExercises(limit: limit, offset: offset, locale: locale)
        } catch let error as AppError {
            throw error
        } catch {
            // AppError にラップする
            throw AppError.unknownError(error.localizedDescription)
        }
    }
}
