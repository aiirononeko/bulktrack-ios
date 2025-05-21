//
//  ExerciseDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct ExerciseDTO: Codable {
    public let id: UUID
    public let name: String
    public let isOfficial: Bool
    public let lastUsedAt: Date?
    public let useCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isOfficial
        case lastUsedAt
        case useCount
    }

    public init(id: UUID, name: String, isOfficial: Bool, lastUsedAt: Date?, useCount: Int?) {
        self.id = id
        self.name = name
        self.isOfficial = isOfficial
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}
