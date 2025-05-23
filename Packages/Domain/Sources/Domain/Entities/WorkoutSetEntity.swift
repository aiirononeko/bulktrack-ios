//
//  WorkoutSetEntity.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public struct WorkoutSetEntity: Equatable {
    public let id: UUID
    public let exerciseId: UUID
    public let setNumber: Int
    public let weight: Double
    public let reps: Int
    public let rpe: Double?
    public let notes: String?
    public let performedAt: Date

    public init(
        id: UUID,
        exerciseId: UUID,
        setNumber: Int,
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        notes: String? = nil,
        performedAt: Date
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.performedAt = performedAt
    }
}

public struct CreateSetRequest: Equatable {
    public let exerciseId: UUID
    public let weight: Double
    public let reps: Int
    public let rpe: Double?
    public let notes: String?
    public let performedAt: Date

    public init(
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        notes: String? = nil,
        performedAt: Date
    ) {
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.performedAt = performedAt
    }
}

public struct UpdateSetRequest: Equatable {
    public let exerciseId: UUID?
    public let weight: Double?
    public let reps: Int?
    public let rpe: Double?
    public let notes: String?
    public let performedAt: Date?

    public init(
        exerciseId: UUID? = nil,
        weight: Double? = nil,
        reps: Int? = nil,
        rpe: Double? = nil,
        notes: String? = nil,
        performedAt: Date? = nil
    ) {
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.performedAt = performedAt
    }
}
