//
//  CreateSetUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public protocol CreateSetUseCaseProtocol {
    func execute(request: CreateSetRequest) async -> Result<WorkoutSetEntity, AppError>
}

public struct CreateSetUseCase: CreateSetUseCaseProtocol {
    private let setRepository: SetRepository
    
    public init(setRepository: SetRepository) {
        self.setRepository = setRepository
    }
    
    public func execute(request: CreateSetRequest) async -> Result<WorkoutSetEntity, AppError> {
        do {
            let workoutSet = try await setRepository.createSet(request)
            return .success(workoutSet)
        } catch {
            return .failure(.unknownError("セットの作成に失敗しました: \(error.localizedDescription)"))
        }
    }
}
