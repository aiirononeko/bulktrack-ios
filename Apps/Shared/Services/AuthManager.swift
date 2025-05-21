import Foundation
import Combine
import Domain // For AuthToken, AuthRepository, SecureStorageServiceProtocol

public protocol AuthManagerProtocol {
    var isAuthenticated: CurrentValueSubject<Bool, Never> { get }
    func getAccessToken() async throws -> String? // Can throw UserFacingAuthError
    func activateDeviceIfNeeded(deviceId: String) async throws // Can throw UserFacingAuthError
    func logout() async throws // Can throw UserFacingAuthError
    // TODO: Add explicit refresh token method if needed by UI
}

@MainActor
public final class AuthManager: ObservableObject, AuthManagerProtocol {

    // MARK: - Published Properties
    public let isAuthenticated: CurrentValueSubject<Bool, Never>
    
    // MARK: - Dependencies
    private let authRepository: AuthRepository
    // No direct need for secureStorage here, as AuthRepository handles it.

    // MARK: - Private State
    private struct TokenState {
        let token: AuthToken
        let expiryDate: Date
    }
    @Published private var tokenState: TokenState?
    private var refreshTokenTask: Task<TokenState?, Error>?
    private let tokenExpiryLeadTime: TimeInterval = 60 // Refresh 60 seconds before actual expiry

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        
        if let initialTokenInfo = try? authRepository.getCurrentAuthTokenInfo() {
            let expiry = initialTokenInfo.retrievedAt.addingTimeInterval(TimeInterval(initialTokenInfo.token.expiresIn))
            self.tokenState = TokenState(token: initialTokenInfo.token, expiryDate: expiry)
            self.isAuthenticated = CurrentValueSubject<Bool, Never>(true)
            
            // Check if token is already expired or close to expiry on init
            Task {
                if isTokenExpiredOrNearExpiry(expiryDate: expiry) {
                    print("[AuthManager] Initial token check: Token expired or near expiry. Attempting refresh.")
                    do {
                        _ = try await refreshAccessToken()
                    } catch {
                        print("[AuthManager] Initial token refresh failed: \(error.localizedDescription)")
                        await clearTokenAndLogoutState()
                    }
                }
            }
        } else {
            self.tokenState = nil
            self.isAuthenticated = CurrentValueSubject<Bool, Never>(false)
        }
    }

    /// Provides the current valid access token, attempting to refresh if needed.
    public func getAccessToken() async throws -> String? {
        guard let currentTokenState = tokenState else {
            // Not strictly an error if called when not authenticated, but could be if expected.
            // For now, returning nil is fine. If an operation requires auth, it should check isAuthenticated first.
            return nil
        }

        if isTokenExpiredOrNearExpiry(expiryDate: currentTokenState.expiryDate) {
            print("[AuthManager] Token expired or near expiry. Attempting refresh.")
            do {
                if let refreshedTokenState = try await refreshAccessToken() {
                    return refreshedTokenState.token.accessToken
                } else {
                    // Refresh attempt did not yield a token, but didn't throw an error directly handled here.
                    // This case might occur if refreshAccessToken itself clears the token.
                    await clearTokenAndLogoutState() // Ensure consistent state
                    throw UserFacingAuthError.refreshTokenFailed(AuthError.noRefreshToken) // Or a more generic error
                }
            } catch {
                print("[AuthManager] Failed to refresh token: \(error.localizedDescription)")
                await clearTokenAndLogoutState()
                throw UserFacingAuthError.refreshTokenFailed(error)
            }
        }
        return currentTokenState.token.accessToken
    }
    
    /// Ensures device is activated if no token exists.
    public func activateDeviceIfNeeded(deviceId: String) async throws {
        if tokenState == nil { // Check against tokenState now
            do {
                print("[AuthManager] No token found, attempting device activation.")
                let newAuthToken = try await authRepository.activateDevice(deviceId: deviceId)
                if let updatedTokenInfo = try? authRepository.getCurrentAuthTokenInfo(), updatedTokenInfo.token.accessToken == newAuthToken.accessToken {
                    self.updateTokenState(with: updatedTokenInfo.token, retrievedAt: updatedTokenInfo.retrievedAt)
                    print("[AuthManager] Device activation successful.")
                } else {
                    self.updateTokenState(with: newAuthToken, retrievedAt: Date())
                    print("[AuthManager] Device activation successful (using local timestamp for expiry).")
                }
            } catch {
                print("[AuthManager] Device activation failed: \(error.localizedDescription)")
                throw UserFacingAuthError.activationFailed(error)
            }
        } else {
            print("[AuthManager] Token already exists, device activation skipped.")
            // Optionally, verify existing token validity here (already done by getAccessToken if called)
        }
    }

    public func logout() async throws {
        guard let currentTokenState = tokenState else {
            print("[AuthManager] No token to logout (already logged out).")
            // Not throwing an error here as it's a valid state if called multiple times.
            return
        }
        do {
            try await authRepository.logout(using: currentTokenState.token.refreshToken)
            print("[AuthManager] Logout successful on server.")
        } catch {
            print("[AuthManager] Server logout failed: \(error.localizedDescription). Clearing local token anyway.")
            // Decide if this should throw. Forcing local logout even if server fails.
            // throw UserFacingAuthError.logoutFailed(error) 
        }
        await clearTokenAndLogoutState() // Always clear local state
    }

    // MARK: - Token Refresh Logic
    // This private method can continue to throw its internal errors (APIError, AuthError, etc.)
    // The public methods calling it (like getAccessToken) will catch and wrap these into UserFacingAuthError.
    private func refreshAccessToken() async throws -> TokenState? {
        guard refreshTokenTask == nil else {
            print("[AuthManager] Refresh already in progress. Awaiting existing task.")
            return try await refreshTokenTask?.value
        }

        guard let currentTokenState = tokenState else {
            throw AuthError.noRefreshToken
        }

        let task = Task<TokenState?, Error> {
            defer { refreshTokenTask = nil }
            print("[AuthManager] Attempting to refresh token.")
            let newAuthToken = try await authRepository.refreshToken(using: currentTokenState.token.refreshToken)
            // Similar to activateDevice, fetch the stored info to get the accurate retrievedAt
            if let updatedTokenInfo = try? authRepository.getCurrentAuthTokenInfo(), updatedTokenInfo.token.accessToken == newAuthToken.accessToken {
                self.updateTokenState(with: updatedTokenInfo.token, retrievedAt: updatedTokenInfo.retrievedAt)
                print("[AuthManager] Token refresh successful.")
                return self.tokenState
            } else {
                // Fallback if fetching info immediately fails
                self.updateTokenState(with: newAuthToken, retrievedAt: Date())
                print("[AuthManager] Token refresh successful (using local timestamp for expiry).")
                return self.tokenState
            }
        }
        self.refreshTokenTask = task
        return try await task.value
    }
    
    private func updateTokenState(with token: AuthToken, retrievedAt: Date) {
        let newExpiryDate = retrievedAt.addingTimeInterval(TimeInterval(token.expiresIn))
        self.tokenState = TokenState(token: token, expiryDate: newExpiryDate)
        self.isAuthenticated.send(true)
        // Saving to Keychain is handled by AuthRepository (APIService) when activate/refresh is called.
        // If we needed to save here (e.g. if AuthManager modified token itself), we'd call:
        // try? authRepository.saveAuthToken(token) // This saves with current Date()
    }

    private func clearTokenAndLogoutState() async {
       if tokenState != nil { // Only try to delete if a token exists
           try? authRepository.deleteCurrentAuthToken()
       }
       self.tokenState = nil
       self.isAuthenticated.send(false)
    }

    private func isTokenExpiredOrNearExpiry(expiryDate: Date) -> Bool {
        return Date() >= expiryDate.addingTimeInterval(-tokenExpiryLeadTime)
    }
}

public enum AuthError: LocalizedError {
    case noRefreshToken
    public var errorDescription: String? {
        switch self {
        case .noRefreshToken: return "リフレッシュトークンがありません。"
        }
    }
}

// MARK: - User-Facing Errors for AuthManager operations

public enum UserFacingAuthError: LocalizedError {
    case activationFailed(Error)
    case refreshTokenFailed(Error)
    case logoutFailed(Error)
    case notAuthenticated // Attempted an operation that requires auth, but not authenticated
    case unknown(Error?)

    public var errorDescription: String? {
        switch self {
        case .activationFailed:
            return "デバイスのアクティベーションに失敗しました。通信環境を確認して再度お試しください。"
        case .refreshTokenFailed:
            return "セッションの更新に失敗しました。再度ログインをお試しください。" // Or specific error from underlying cause
        case .logoutFailed:
            return "ログアウト処理中にエラーが発生しました。"
        case .notAuthenticated:
            return "認証されていません。ログインしてください。"
        case .unknown:
            return "不明な認証エラーが発生しました。"
        }
    }
    
    // Optionally, provide the underlying error for logging or debugging
    public var underlyingError: Error? {
        switch self {
        case .activationFailed(let concreteError):
            return concreteError
        case .refreshTokenFailed(let concreteError):
            return concreteError
        case .logoutFailed(let concreteError):
            return concreteError
        case .unknown(let optionalError): // optionalError is of type Error?
            return optionalError
        case .notAuthenticated:
            return nil
        }
    }
}
