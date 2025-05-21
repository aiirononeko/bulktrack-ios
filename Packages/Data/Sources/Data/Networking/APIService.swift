//
//  APIService.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Domain
// No need to import Data here as DTOs/Mappers are used internally or via Domain types.
// However, if DTOs are directly exposed or used in signatures, it might be needed.
// For now, let's assume DTOs are encapsulated. If ExerciseDTO is from Data package, it's fine.

public final class APIService: ExerciseRepository, AuthRepository {

    private let networkClient: NetworkClientProtocol
    private let secureStorageService: SecureStorageServiceProtocol
    private let jsonDecoder: JSONDecoder
    private let accessTokenProvider: (() async throws -> String?)? // Changed to throws

    // TODO: Inject dependencies via DIContainer for better testability
    public init(
        networkClient: NetworkClientProtocol = NetworkClient(),
        secureStorageService: SecureStorageServiceProtocol = KeychainService(), // Default for convenience
        accessTokenProvider: (() async throws -> String?)? = nil // Changed to throws. Injected by App layer.
    ) {
        self.networkClient = networkClient
        self.secureStorageService = secureStorageService
        self.accessTokenProvider = accessTokenProvider
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601 // Ensure DTO dates are decoded correctly
    }

    // MARK: - Helper to get authenticated headers
    private func getAuthenticatedHeaders() async throws -> [String: String] { // Changed to throws
        var headers = ["Content-Type": "application/json"]
        // Call the provider, which might throw. The error should propagate.
        if let token = try await accessTokenProvider?() {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }

    // MARK: - ExerciseRepository Conformance

    public func recentExercises(
        limit: Int,
        offset: Int,
        locale: String // locale is not used by /v1/me/exercises/recent endpoint in OpenAPI spec
    ) async throws -> [ExerciseEntity] {
        
        let headers = try await getAuthenticatedHeaders() // Changed to try await
        let endpoint = RecentExercisesEndpoint(limit: limit, offset: offset, customHeaders: headers)
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
    var customHeaders: [String: String]? // Renamed to avoid conflict with protocol's headers

    var path: String { "/me/exercises/recent" }
    var method: HTTPMethod { .get }
    var parameters: [String : Any]? {
        ["limit": String(limit), "offset": String(offset)]
    }
    var headers: [String : String]? { customHeaders }
}

// MARK: - Auth Endpoints

private struct ActivateDeviceEndpoint: Endpoint {
    let deviceId: String

    var path: String { "/auth/device" }
    var method: HTTPMethod { .post }
    var headers: [String : String]? {
        // Specific header for this endpoint. Does not use default Authorization.
        return [
            "Content-Type": "application/json",
            "X-Device-Id": deviceId
        ]
    }
    // No body or parameters for this specific POST
}

private struct RefreshTokenEndpoint: Endpoint {
    let refreshTokenValue: String

    var path: String { "/auth/refresh" }
    var method: HTTPMethod { .post }
    var body: Data? {
        try? JSONEncoder().encode(RefreshTokenRequestDTO(refreshToken: refreshTokenValue))
    }
    // This endpoint does not require Bearer auth.
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}

private struct LogoutEndpoint: Endpoint {
    let refreshTokenValue: String
    var customHeaders: [String: String]? // For consistency, though Logout might need specific auth header

    var path: String { "/auth/logout" }
    var method: HTTPMethod { .post }
    var body: Data? {
        try? JSONEncoder().encode(RefreshTokenRequestDTO(refreshToken: refreshTokenValue))
    }
    var headers: [String : String]? { customHeaders }
}


// MARK: - AuthRepository Conformance

extension APIService {
    public func activateDevice(deviceId: String) async throws -> AuthToken {
        let endpoint = ActivateDeviceEndpoint(deviceId: deviceId)
        // Assuming TokenResponse is the DTO for auth responses
        let tokenResponseDTO = try await networkClient.sendRequest(endpoint: endpoint, decoder: jsonDecoder) as TokenResponse
        let authToken = TokenMapper.toEntity(dto: tokenResponseDTO)
        try saveAuthToken(authToken) // Save after successful activation
        return authToken
    }

    public func refreshToken(using currentRefreshToken: String) async throws -> AuthToken {
        let endpoint = RefreshTokenEndpoint(refreshTokenValue: currentRefreshToken)
        let tokenResponseDTO = try await networkClient.sendRequest(endpoint: endpoint, decoder: jsonDecoder) as TokenResponse
        let newAuthToken = TokenMapper.toEntity(dto: tokenResponseDTO)
        try saveAuthToken(newAuthToken) // Save the new token
        return newAuthToken
    }

    public func logout(using currentRefreshToken: String) async throws {
        let headers = try await getAuthenticatedHeaders() // Changed to try await. Logout usually requires authentication.
        let endpoint = LogoutEndpoint(refreshTokenValue: currentRefreshToken, customHeaders: headers)
        // This is a non-Decodable request (expects 204 No Content)
        try await networkClient.sendRequest(endpoint: endpoint)
        try deleteCurrentAuthToken() // Delete token after successful logout
    }

    public func saveAuthToken(_ token: AuthToken) throws {
        try secureStorageService.saveTokenInfo(token: token, retrievedAt: Date())
    }

    public func getCurrentAuthToken() throws -> AuthToken? {
        try secureStorageService.getTokenInfo()?.token
    }
    
    public func getCurrentAuthTokenInfo() throws -> (token: AuthToken, retrievedAt: Date)? {
        try secureStorageService.getTokenInfo()
    }

    public func deleteCurrentAuthToken() throws {
        try secureStorageService.deleteTokenInfo()
    }
}

// TODO: Add other endpoints like SearchExercisesEndpoint, etc.
