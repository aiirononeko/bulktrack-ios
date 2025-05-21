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

    public init(
        id: UUID = UUID(),
        name: String,
        isOfficial: Bool? = nil,
        lastUsedAt: ISODate? = nil,
        useCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.isOfficial = isOfficial
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}
