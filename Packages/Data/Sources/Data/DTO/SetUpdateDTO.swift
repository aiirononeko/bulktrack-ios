//
//  SetUpdateDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public struct SetUpdateDTO: Codable {
    public let exerciseId: UUID?
    public let weight: Double?
    public let reps: Int?
    public let rpe: Double?
    public let notes: String?
    public let performedAt: Date?

    enum CodingKeys: String, CodingKey {
        case exerciseId
        case weight
        case reps
        case rpe
        case notes
        case performedAt
    }

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
