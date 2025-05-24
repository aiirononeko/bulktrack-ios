//
//  LocalWorkoutSetEntity.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/25.
//

import Foundation

public struct LocalWorkoutSetEntity: Equatable {
    public let id: UUID
    public let exerciseId: UUID
    public let setNumber: Int
    public let weight: Double
    public let reps: Int
    public let rpe: Double?
    public let performedAt: Date

    public init(
        id: UUID,
        exerciseId: UUID,
        setNumber: Int,
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        performedAt: Date
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.performedAt = performedAt
    }
}
