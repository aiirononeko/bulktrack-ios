//
//  DeleteSetUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public protocol DeleteSetUseCaseProtocol {
    func execute(setId: UUID) async -> Result<Void, AppError>
}

public struct DeleteSetUseCase: DeleteSetUseCaseProtocol {
    private let setRepository: SetRepository
    private let workoutHistoryRepository: WorkoutHistoryRepository
    
    public init(
        setRepository: SetRepository,
        workoutHistoryRepository: WorkoutHistoryRepository
    ) {
        self.setRepository = setRepository
        self.workoutHistoryRepository = workoutHistoryRepository
    }
    
    public func execute(setId: UUID) async -> Result<Void, AppError> {
        do {
            // 1. APIから削除
            try await setRepository.deleteSet(setId: setId)
            
            // 2. ローカルから削除
            try await workoutHistoryRepository.deleteWorkoutSet(setId)
            
            return .success(())
        } catch {
            return .failure(.unknownError("セットの削除に失敗しました: \(error.localizedDescription)"))
        }
    }
}
