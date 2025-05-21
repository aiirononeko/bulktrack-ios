//
//  WorkoutSetDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct WorkoutSetDTO: Codable {
    public let id: UUID
    public let exerciseId: UUID
    public let setNumber: Int
    public let exerciseName: String
    public let weight: Double
    public let reps: Int
    public let rpe: Double?
    public let notes: String?
    public let performedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId
        case setNumber
        case exerciseName
        case weight
        case reps
        case rpe
        case notes
        case performedAt
    }

    public init(id: UUID, exerciseId: UUID, setNumber: Int, exerciseName: String, weight: Double, reps: Int, rpe: Double?, notes: String?, performedAt: Date) {
        self.id = id
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.performedAt = performedAt
    }
}
