//
//  GetWorkoutHistoryUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/25.
//

import Foundation

public protocol GetWorkoutHistoryUseCaseProtocol {
    func execute(exerciseId: UUID) async -> Result<WorkoutHistoryData, AppError>
}

public struct WorkoutHistoryData {
    public let previousWorkout: WorkoutHistoryEntity?
    public let todaysSets: [LocalWorkoutSetEntity]
    
    public init(previousWorkout: WorkoutHistoryEntity?, todaysSets: [LocalWorkoutSetEntity]) {
        self.previousWorkout = previousWorkout
        self.todaysSets = todaysSets
    }
}

public struct GetWorkoutHistoryUseCase: GetWorkoutHistoryUseCaseProtocol {
    private let workoutHistoryRepository: WorkoutHistoryRepository
    
    public init(workoutHistoryRepository: WorkoutHistoryRepository) {
        self.workoutHistoryRepository = workoutHistoryRepository
    }
    
    public func execute(exerciseId: UUID) async -> Result<WorkoutHistoryData, AppError> {
        do {
            // 前回のワークアウトと今日のセットを順次取得
            let previousWorkout = try await workoutHistoryRepository.getPreviousWorkout(exerciseId: exerciseId)
            let todaysSets = try await workoutHistoryRepository.getTodaysSets(exerciseId: exerciseId)
            
            let data = WorkoutHistoryData(
                previousWorkout: previousWorkout,
                todaysSets: todaysSets
            )
            
            return .success(data)
        } catch {
            return .failure(.unknownError("ワークアウト履歴の取得に失敗しました: \(error.localizedDescription)"))
        }
    }
}
