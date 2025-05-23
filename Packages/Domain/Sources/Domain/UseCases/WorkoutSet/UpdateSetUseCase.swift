//
//  UpdateSetUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public protocol UpdateSetUseCaseProtocol {
    func execute(setId: UUID, request: UpdateSetRequest, locale: String?) async -> Result<WorkoutSetEntity, AppError>
}

public struct UpdateSetUseCase: UpdateSetUseCaseProtocol {
    private let setRepository: SetRepository
    
    public init(setRepository: SetRepository) {
        self.setRepository = setRepository
    }
    
    public func execute(setId: UUID, request: UpdateSetRequest, locale: String? = nil) async -> Result<WorkoutSetEntity, AppError> {
        do {
            let workoutSet = try await setRepository.updateSet(setId: setId, request: request, locale: locale)
            return .success(workoutSet)
        } catch {
            return .failure(.unknownError("セットの更新に失敗しました: \(error.localizedDescription)"))
        }
    }
}
