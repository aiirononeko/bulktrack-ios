//
//  HandleRecentExercisesRequestUseCase.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public protocol HandleRecentExercisesRequestUseCaseProtocol {
    func execute(limit: Int) async throws -> [ExerciseEntity]
}

public final class HandleRecentExercisesRequestUseCase: HandleRecentExercisesRequestUseCaseProtocol {
    private let exerciseRepository: ExerciseRepository

    public init(exerciseRepository: ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }

    public func execute(limit: Int) async throws -> [ExerciseEntity] {
        // localeをどうするか検討。現状のExerciseRepository.recentExercisesはlocaleを必須引数としている。
        // WCSession経由のリクエストではlocale情報が渡ってこない場合、デフォルト値を使うか、
        // RepositoryのシグネチャをOptionalにするか、あるいはiPhoneの現在のlocaleを使うか。
        // ここでは仮にiPhoneの現在のlocaleを使うとする。
        let currentLocale = Locale.current.identifier
        return try await exerciseRepository.recentExercises(limit: limit, offset: 0, locale: currentLocale)
        // offsetは0で固定。ページネーションが必要な場合は引数に追加する。
    }
}
