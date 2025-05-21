//
//  ExerciseEntity.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct ExerciseEntity: Equatable, Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let isOfficial: Bool?
    public let lastUsedAt: ISODate?
    public let useCount: Int?
}
