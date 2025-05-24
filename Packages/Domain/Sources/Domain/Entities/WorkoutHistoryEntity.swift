//
//  WorkoutHistoryEntity.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/25.
//

import Foundation

public struct WorkoutHistoryEntity: Equatable {
    public let id: UUID
    public let exerciseId: UUID
    public let exerciseName: String
    public let performedAt: Date  // 日付（時刻は無視）
    public let sets: [WorkoutSetEntity]

    public init(
        id: UUID,
        exerciseId: UUID,
        exerciseName: String,
        performedAt: Date,
        sets: [WorkoutSetEntity]
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.performedAt = performedAt
        self.sets = sets
    }
}
