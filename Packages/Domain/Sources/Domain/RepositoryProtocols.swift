//
//  RepositoryProtocols.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Combine

public protocol SessionSyncRepository {
    /// iPhone との到達可能性
    var isReachable: Bool { get }

    /// iPhone から push される「最近種目」のストリーム
    var recentExercisesPublisher: AnyPublisher<[ExerciseEntity], Error> { get }

    /// iPhone に対して「最近種目を送って」と依頼
    func requestRecentExercises(limit: Int)

    /// WCSession.activate() 相当。App 起動時に 1 回呼び出す
    func activate()
}

public protocol ExerciseRepository {
    /// クエリ検索（検索語が nil なら全件）
    func searchExercises(query: String?, locale: String?) async throws -> [ExerciseEntity]

    /// 最近使った種目を取得
    func recentExercises(limit: Int, offset: Int, locale: String?) async throws -> [ExerciseEntity]
}

// MARK: - Secure Storage for Tokens

public enum SecureStorageError: Error, LocalizedError {
    case saveFailed(Error?)
    case itemNotFound
    case deleteFailed(Error?)
    case unknown(Error?)

    public var errorDescription: String? {
        switch self {
        case .saveFailed: return "トークンの保存に失敗しました。"
        case .itemNotFound: return "トークンが見つかりません。"
        case .deleteFailed: return "トークンの削除に失敗しました。"
        case .unknown: return "不明なストレージエラーが発生しました。"
        }
    }
}

public protocol SecureStorageServiceProtocol {
    /// Saves the authentication token and its retrieval timestamp securely.
    /// - Parameters:
    ///   - token: The `AuthToken` to save.
    ///   - retrievedAt: The `Date` when the token was retrieved.
    /// - Throws: `SecureStorageError` if saving fails.
    func saveTokenInfo(token: AuthToken, retrievedAt: Date) throws

    /// Retrieves the authentication token and its retrieval timestamp.
    /// - Returns: A tuple `(token: AuthToken, retrievedAt: Date)`, or `nil` if not found.
    /// - Throws: `SecureStorageError` if retrieval fails for reasons other than not found.
    func getTokenInfo() throws -> (token: AuthToken, retrievedAt: Date)?

    /// Deletes the currently stored authentication token information.
    /// - Throws: `SecureStorageError` if deletion fails.
    func deleteTokenInfo() throws
}

// MARK: - Dashboard

public protocol DashboardRepository {
    func fetchDashboard(span: String, locale: String?) async -> Result<DashboardEntity, AppError>
}

// MARK: - Authentication

public protocol AuthManagerProtocol {
    var isAuthenticated: CurrentValueSubject<Bool, Never> { get }
    func getAccessToken() async throws -> String?
    func activateDeviceIfNeeded(deviceId: String) async throws
    func logout() async throws
    func getRefreshTokenForLogout() async throws -> String?
    func loginWithNewToken(_ token: AuthToken, retrievedAt: Date) async throws
}

public protocol AuthRepository {
    /// Activates a new device (anonymous onboarding).
    /// - Parameter deviceId: The unique identifier for the device.
    /// - Returns: An `AuthToken` containing access and refresh tokens.
    /// - Throws: APIError or other network/parsing errors.
    func activateDevice(deviceId: String) async throws -> AuthToken

    /// Refreshes the access token using a refresh token.
    /// - Parameter currentRefreshToken: The current refresh token.
    /// - Returns: A new `AuthToken`.
    /// - Throws: APIError or other network/parsing errors.
    func refreshToken(using currentRefreshToken: String) async throws -> AuthToken

    /// Logs out the user by revoking the refresh token.
    /// - Parameter currentRefreshToken: The current refresh token to be revoked.
    /// - Throws: APIError or other network/parsing errors.
    func logout(using currentRefreshToken: String) async throws

    // Token management convenience, often wrapping SecureStorageService
    
    /// Saves the authentication token.
    /// - Parameter token: The `AuthToken` to save.
    /// - Throws: `SecureStorageError` if saving fails.
    func saveAuthToken(_ token: AuthToken) throws // Internally, this will use current Date for retrievedAt
    
    /// Retrieves the current authentication token.
    /// - Returns: The saved `AuthToken`, or `nil` if not found.
    /// - Throws: `SecureStorageError` if retrieval fails.
    func getCurrentAuthToken() throws -> AuthToken? // Returns only the token part

    /// Retrieves the current authentication token along with its retrieval timestamp.
    /// - Returns: A tuple `(token: AuthToken, retrievedAt: Date)`, or `nil` if not found.
    /// - Throws: `SecureStorageError` if retrieval fails.
    func getCurrentAuthTokenInfo() throws -> (token: AuthToken, retrievedAt: Date)?
    
    /// Deletes the current authentication token.
    /// - Throws: `SecureStorageError` if deletion fails.
    func deleteCurrentAuthToken() throws
}

// MARK: - Set Repository

public protocol SetRepository {
    /// Creates a new workout set
    /// - Parameter request: The set creation request
    /// - Returns: The created workout set
    /// - Throws: APIError or other network/parsing errors
    func createSet(_ request: CreateSetRequest) async throws -> WorkoutSetEntity
    
    /// Updates an existing workout set
    /// - Parameters:
    ///   - setId: The ID of the set to update
    ///   - request: The update request containing the fields to modify
    ///   - locale: Optional locale for localized exercise names
    /// - Returns: The updated workout set
    /// - Throws: APIError or other network/parsing errors
    func updateSet(setId: UUID, request: UpdateSetRequest, locale: String?) async throws -> WorkoutSetEntity
    
    /// Deletes a workout set
    /// - Parameter setId: The ID of the set to delete
    /// - Throws: APIError or other network/parsing errors
    func deleteSet(setId: UUID) async throws
    
    /// Fetches workout sets with optional filtering
    /// - Parameters:
    ///   - limit: Maximum number of sets to return
    ///   - offset: Pagination offset
    ///   - date: Optional date filter (YYYY-MM-DD)
    ///   - exerciseId: Optional exercise ID filter
    ///   - sortBy: Sort order (performedAt_asc or performedAt_desc)
    ///   - locale: Optional locale for localized exercise names
    /// - Returns: Array of workout sets
    /// - Throws: APIError or other network/parsing errors
    func fetchSets(
        limit: Int,
        offset: Int,
        date: String?,
        exerciseId: UUID?,
        sortBy: String?,
        locale: String?
    ) async throws -> [WorkoutSetEntity]
}

// MARK: - Workout History Repository

public protocol WorkoutHistoryRepository {
    /// ローカル保存（同時にクリーンアップ実行）
    /// - Parameter set: The local workout set to save
    /// - Throws: Storage error if saving fails
    func saveWorkoutSet(_ set: LocalWorkoutSetEntity) async throws
    
    /// 前回のワークアウト取得（指定種目の最新日付のセット群）
    /// - Parameter exerciseId: The exercise ID to get previous workout for
    /// - Returns: The previous workout history, or nil if no previous data exists
    /// - Throws: Storage error if fetching fails
    func getPreviousWorkout(exerciseId: UUID) async throws -> WorkoutHistoryEntity?
    
    /// 今日のセット取得
    /// - Parameter exerciseId: The exercise ID to get today's sets for
    /// - Returns: Array of today's workout sets
    /// - Throws: Storage error if fetching fails
    func getTodaysSets(exerciseId: UUID) async throws -> [LocalWorkoutSetEntity]
}
