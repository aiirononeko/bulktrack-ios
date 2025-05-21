//
//  APIService.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Domain

public final class APIService: ExerciseRepository {

    public init() {}

    public func recentExercises(
        limit: Int,
        offset: Int,
        locale: String
    ) async throws -> [ExerciseEntity] {

        return (0..<limit).map { idx in
            ExerciseEntity(
                name: "デモ種目 \(idx)",
                isOfficial: idx.isMultiple(of: 2)
            )
        }
    }

    public func searchExercises(
        query: String?,
        locale: String?
    ) async throws -> [ExerciseEntity] {

        try await recentExercises(
            limit: 5,
            offset: 0,
            locale: locale ?? "ja"
        )
    }
}
