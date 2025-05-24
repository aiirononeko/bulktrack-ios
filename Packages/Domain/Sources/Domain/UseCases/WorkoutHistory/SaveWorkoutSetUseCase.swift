//
//  SaveWorkoutSetUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/25.
//

import Foundation

public protocol SaveWorkoutSetUseCaseProtocol {
    func execute(request: CreateSetRequest, exerciseName: String) async -> Result<WorkoutSetEntity, AppError>
}

public struct SaveWorkoutSetUseCase: SaveWorkoutSetUseCaseProtocol {
    private let setRepository: SetRepository
    private let workoutHistoryRepository: WorkoutHistoryRepository
    
    public init(
        setRepository: SetRepository,
        workoutHistoryRepository: WorkoutHistoryRepository
    ) {
        self.setRepository = setRepository
        self.workoutHistoryRepository = workoutHistoryRepository
    }
    
    public func execute(request: CreateSetRequest, exerciseName: String) async -> Result<WorkoutSetEntity, AppError> {
        do {
            // 1. APIに保存
            let workoutSet = try await setRepository.createSet(request)
            
            // 2. ローカルに保存（今日のセット数を取得してsetNumberを決定）
            let todaysSets = try await workoutHistoryRepository.getTodaysSets(exerciseId: request.exerciseId)
            let setNumber = todaysSets.count + 1
            
            let localSet = LocalWorkoutSetEntity(
                id: workoutSet.id,
                exerciseId: request.exerciseId,
                setNumber: setNumber,
                weight: request.weight,
                reps: request.reps,
                rpe: request.rpe,
                performedAt: request.performedAt
            )
            
            try await workoutHistoryRepository.saveWorkoutSet(localSet)
            
            return .success(workoutSet)
        } catch {
            return .failure(.unknownError("セットの保存に失敗しました: \(error.localizedDescription)"))
        }
    }
}
