//
//  APIService.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Domain
import Data // For DTOs and Mappers

public final class APIService: ExerciseRepository {

    private let networkClient: NetworkClientProtocol
    private let jsonDecoder: JSONDecoder

    // TODO: Inject NetworkClient via DIContainer for better testability
    public init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601 // Ensure DTO dates are decoded correctly
    }

    // MARK: - ExerciseRepository Conformance

    public func recentExercises(
        limit: Int,
        offset: Int,
        locale: String // locale is not used by /v1/me/exercises/recent endpoint in OpenAPI spec
    ) async throws -> [ExerciseEntity] {
        
        let endpoint = RecentExercisesEndpoint(limit: limit, offset: offset)
        let dtos = try await networkClient.sendRequest(endpoint: endpoint, decoder: jsonDecoder) as [ExerciseDTO]
        return ExerciseMapper.toEntities(dtos: dtos)
    }

    public func searchExercises(
        query: String?,
        locale: String?
    ) async throws -> [ExerciseEntity] {
        // TODO: Implement actual searchExercises API call
        // For now, returning mock or a subset of recent as placeholder
        print("searchExercises called with query: \(query ?? "nil"), locale: \(locale ?? "nil") - NOT IMPLEMENTED, returning recent as placeholder")
        return try await recentExercises(limit: 5, offset: 0, locale: locale ?? "ja")
    }
}

// MARK: - Endpoints Definitions

private struct RecentExercisesEndpoint: Endpoint {
    let limit: Int
    let offset: Int

    var path: String { "/me/exercises/recent" }
    var method: HTTPMethod { .get }
    var parameters: [String : Any]? {
        ["limit": String(limit), "offset": String(offset)]
    }
    // Headers will use the default from Endpoint extension,
    // which should include Authorization if AuthManager is set up.
}

// TODO: Add other endpoints like SearchExercisesEndpoint, etc.
