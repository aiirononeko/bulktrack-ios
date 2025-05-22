import Foundation
import Combine
import Domain // For AuthToken, AuthRepository, SecureStorageServiceProtocol, DeviceIdentifierServiceProtocol (assuming it's here or in Data)
import Data // To access APIError

@MainActor
public final class AuthManager: ObservableObject, AuthManagerProtocol {

    public let isAuthenticated: CurrentValueSubject<Bool, Never>
    
    private let authRepository: AuthRepository
    private let deviceIdentifierService: DeviceIdentifierServiceProtocol
    private let userDefaults: UserDefaults

    private struct TokenState {
        let token: AuthToken
        let expiryDate: Date
    }
    @Published private var tokenState: TokenState?
    private var refreshTokenTask: Task<TokenState?, Error>?
    private let tokenExpiryLeadTime: TimeInterval = 60

    private let lastSilentActivationAttemptKey = "AuthManager.lastSilentActivationAttemptDate"
    private let silentActivationCooldown: TimeInterval = 24 * 60 * 60 // 24 hours

    private let maxRetryAttempts = 3
    private let initialRetryDelay: TimeInterval = 1.0

    public init(
        authRepository: AuthRepository,
        deviceIdentifierService: DeviceIdentifierServiceProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.authRepository = authRepository
        self.deviceIdentifierService = deviceIdentifierService
        self.userDefaults = userDefaults
        
        if let initialTokenInfo = try? authRepository.getCurrentAuthTokenInfo() {
            let expiry = initialTokenInfo.retrievedAt.addingTimeInterval(TimeInterval(initialTokenInfo.token.expiresIn))
            self.tokenState = TokenState(token: initialTokenInfo.token, expiryDate: expiry)
            self.isAuthenticated = CurrentValueSubject<Bool, Never>(true)
            print("[DEBUG][AuthManager] Token initialized. AccessToken: \(initialTokenInfo.token.accessToken.prefix(4))... Expiry: \(expiry)")
            
            Task {
                if isTokenExpiredOrNearExpiry(expiryDate: expiry) {
                    print("[AuthManager] Initial token check: Token expired or near expiry. Attempting refresh.")
                    do {
                        _ = try await refreshAccessTokenInternal() // Use internal refresh
                    } catch let error as APIError where error.isInvalidGrantError() {
                        print("[AuthManager] Initial token refresh failed (invalid grant): \(error.localizedDescription). Details: \(error.detailedServerErrorInfo ?? "N/A")")
                        // Don't attempt silent activation on init failure, just log out.
                        await clearTokenAndLogoutState()
                    }
                    catch let error as APIError {
                        print("[AuthManager] Initial token refresh failed with APIError: \(error.localizedDescription). Details: \(error.detailedServerErrorInfo ?? "N/A")")
                        await clearTokenAndLogoutState()
                    } catch {
                        print("[AuthManager] Initial token refresh failed with other error: \(error.localizedDescription)")
                        await clearTokenAndLogoutState()
                    }
                }
            }
        } else {
            self.tokenState = nil
            self.isAuthenticated = CurrentValueSubject<Bool, Never>(false)
        }
    }

    public func getAccessToken() async throws -> String? {
        print("[AuthManager getAccessToken] Entered.")
        guard let currentTokenState = tokenState else {
            print("[AuthManager getAccessToken] currentTokenState is nil. No token available.")
            // If no token, higher level logic should prompt for activation/login.
            // Consider if silent activation should be attempted here if app starts without token.
            // For now, focusing on refresh failure recovery.
            return nil
        }
        print("[AuthManager getAccessToken] Current token exists. Expiry: \(currentTokenState.expiryDate)")

        if isTokenExpiredOrNearExpiry(expiryDate: currentTokenState.expiryDate) {
            print("[AuthManager getAccessToken] Token expired or near expiry. Attempting refresh.")
            do {
                if let refreshedTokenState = try await refreshAccessTokenInternal() {
                    print("[AuthManager getAccessToken] Refresh successful. Returning new token: \(refreshedTokenState.token.accessToken.prefix(4))...")
                    return refreshedTokenState.token.accessToken
                } else {
                    // This path should ideally not be hit if refreshAccessTokenInternal throws or returns a valid state.
                    print("[AuthManager getAccessToken] refreshAccessTokenInternal returned nil unexpectedly. Clearing token and throwing.")
                    await clearTokenAndLogoutState()
                    throw UserFacingAuthError.refreshTokenFailed(AuthError.unknown(nil))
                }
            } catch let error where isUnrecoverableRefreshTokenError(error) {
                print("[AuthManager getAccessToken] Unrecoverable refresh token error: \(error.localizedDescription). Attempting silent activation.")
                do {
                    if let newAccessToken = try await attemptSilentDeviceActivation() {
                        print("[AuthManager getAccessToken] Silent activation successful. Returning new token.")
                        return newAccessToken
                    } else {
                        // Silent activation attempted but didn't yield a token (e.g. cooldown, or it failed and threw)
                        // If attemptSilentDeviceActivation throws AuthError.silentActivationCooldown, it will be caught below.
                        // If it throws another error (like activationFailed), it's also caught below.
                        // This 'else' might not be reachable if attemptSilentDeviceActivation always throws or returns token.
                        print("[AuthManager getAccessToken] Silent activation did not yield a token and did not throw an expected error. Clearing token.")
                        await clearTokenAndLogoutState()
                        throw UserFacingAuthError.activationFailed(AuthError.unknown(nil)) // Should be more specific
                    }
                } catch let activationError as AuthError where activationError == .silentActivationCooldown {
                    print("[AuthManager getAccessToken] Silent activation on cooldown. Clearing token and rethrowing original refresh error.")
                    await clearTokenAndLogoutState()
                    throw UserFacingAuthError.refreshTokenFailed(error) // Rethrow original unrecoverable refresh error
                }
                catch let activationError { // Catch other errors from attemptSilentDeviceActivation
                    print("[AuthManager getAccessToken] Silent activation failed: \(activationError.localizedDescription). Clearing token.")
                    await clearTokenAndLogoutState()
                    throw UserFacingAuthError.activationFailed(activationError)
                }
            } catch let error { // Catch other errors from refreshAccessTokenInternal (e.g., network after retries)
                print("[AuthManager getAccessToken] Failed to refresh token: \(error.localizedDescription). Clearing token.")
                await clearTokenAndLogoutState()
                throw UserFacingAuthError.refreshTokenFailed(error)
            }
        }
        print("[AuthManager getAccessToken] Token not expired. Returning current token: \(currentTokenState.token.accessToken.prefix(4))...")
        return currentTokenState.token.accessToken
    }
    
    public func activateDeviceIfNeeded(deviceId: String) async throws {
        if tokenState == nil {
            do {
                print("[AuthManager] No token found, attempting device activation.")
                let newAuthToken = try await authRepository.activateDevice(deviceId: deviceId)
                // Fetch from repo to get accurate retrievedAt if possible
                if let updatedTokenInfo = try? authRepository.getCurrentAuthTokenInfo(), updatedTokenInfo.token.accessToken == newAuthToken.accessToken {
                    self.updateTokenState(with: updatedTokenInfo.token, retrievedAt: updatedTokenInfo.retrievedAt)
                } else {
                    self.updateTokenState(with: newAuthToken, retrievedAt: Date()) // Fallback to local time
                }
                print("[AuthManager] Device activation successful.")
            } catch {
                print("[AuthManager] Device activation failed: \(error.localizedDescription)")
                throw UserFacingAuthError.activationFailed(error)
            }
        } else {
            print("[AuthManager] Token already exists, device activation skipped.")
        }
    }

    public func logout() async throws {
        guard let currentTokenState = tokenState else {
            print("[AuthManager] No token to logout (already logged out).")
            return
        }
        do {
            try await authRepository.logout(using: currentTokenState.token.refreshToken)
            print("[AuthManager] Logout successful on server.")
        } catch {
            print("[AuthManager] Server logout failed: \(error.localizedDescription). Clearing local token anyway.")
        }
        await clearTokenAndLogoutState()
    }

    private func refreshAccessTokenInternal() async throws -> TokenState? {
        guard refreshTokenTask == nil else {
            print("[AuthManager] Refresh already in progress. Awaiting existing task.")
            return try await refreshTokenTask?.value
        }

        guard let currentTokenState = tokenState else {
            throw AuthError.noRefreshToken // No current token to refresh
        }

        let task = Task<TokenState?, Error> { [weak self] in
            guard let self = self else { throw AuthError.unknown(nil) }
            
            defer { self.refreshTokenTask = nil }
            let tokenToRefresh = currentTokenState.token.refreshToken
            
            guard !tokenToRefresh.isEmpty else {
                print("[AuthManager] Refresh token is empty. Aborting refresh.")
                throw AuthError.noRefreshToken // Treat as unrecoverable for refresh
            }
            print("[AuthManager] Attempting to refresh token. RefreshToken (prefix): \(tokenToRefresh.prefix(4))...")

            var attempts = 0
            while attempts < self.maxRetryAttempts {
                attempts += 1
                do {
                    let newAuthToken = try await self.authRepository.refreshToken(using: tokenToRefresh)
                    if let updatedTokenInfo = try? self.authRepository.getCurrentAuthTokenInfo(), updatedTokenInfo.token.accessToken == newAuthToken.accessToken {
                        self.updateTokenState(with: updatedTokenInfo.token, retrievedAt: updatedTokenInfo.retrievedAt)
                    } else {
                        self.updateTokenState(with: newAuthToken, retrievedAt: Date())
                    }
                    print("[AuthManager] Token refresh successful on attempt \(attempts).")
                    return self.tokenState
                } catch let error as APIError {
                    print("[AuthManager] Refresh attempt \(attempts) failed with APIError: \(error.localizedDescription). Details: \(error.detailedServerErrorInfo ?? "N/A")")
                    if error.isInvalidGrantError() { // Assumes APIError.isInvalidGrantError() exists
                        print("[AuthManager] Refresh token is invalid. No more retries.")
                        throw error // Propagate to trigger silent activation path in getAccessToken
                    }
                    if attempts >= self.maxRetryAttempts || !error.isRetryableNetworkError() { // Assumes APIError.isRetryableNetworkError() exists
                        throw error
                    }
                    let delay = pow(2.0, Double(attempts - 1)) * self.initialRetryDelay
                    print("[AuthManager] Retrying refresh in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch { // Catch other errors
                    print("[AuthManager] Refresh attempt \(attempts) failed with other error: \(error.localizedDescription)")
                    if attempts >= self.maxRetryAttempts {
                        throw error
                    }
                    // For generic errors, assume retryable for now, or add more specific checks
                    let delay = pow(2.0, Double(attempts - 1)) * self.initialRetryDelay
                    print("[AuthManager] Retrying refresh in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
            // Fallback if loop finishes without returning/throwing (should not happen)
            throw AuthError.refreshTokenFailed(nil)
        }
        self.refreshTokenTask = task
        return try await task.value
    }
    
    private func updateTokenState(with token: AuthToken, retrievedAt: Date) {
        let newExpiryDate = retrievedAt.addingTimeInterval(TimeInterval(token.expiresIn))
        self.tokenState = TokenState(token: token, expiryDate: newExpiryDate)
        self.isAuthenticated.send(true)
        print("[DEBUG][AuthManager] Token state updated. AccessToken: \(token.accessToken.prefix(4))... New Expiry: \(newExpiryDate)")
    }

    private func clearTokenAndLogoutState() async {
       if tokenState != nil {
           try? authRepository.deleteCurrentAuthToken()
       }
       self.tokenState = nil
       self.isAuthenticated.send(false)
       print("[AuthManager] Token cleared and logged out state set.")
    }

    private func isTokenExpiredOrNearExpiry(expiryDate: Date) -> Bool {
        let checkDate = Date()
        // print("[DEBUG][AuthManager] Checking token expiry. Current: \(checkDate), Expiry: \(expiryDate), LeadTime: \(tokenExpiryLeadTime)")
        return checkDate >= expiryDate.addingTimeInterval(-tokenExpiryLeadTime)
    }

    // MARK: - Silent Activation Helpers

    private func isUnrecoverableRefreshTokenError(_ error: Error) -> Bool {
        if let apiError = error as? APIError, apiError.isInvalidGrantError() { // Assumes APIError.isInvalidGrantError() exists
            return true
        }
        if let authError = error as? AuthError, authError == .noRefreshToken {
            return true
        }
        return false
    }

    private func attemptSilentDeviceActivation() async throws -> String? {
        print("[AuthManager] Attempting silent device activation.")
        guard canAttemptSilentActivation() else {
            print("[AuthManager] Silent activation conditions not met (cooldown).")
            throw AuthError.silentActivationCooldown
        }

        do {
            let deviceId = try deviceIdentifierService.getDeviceIdentifier()
            
            // Temporarily clear token state to allow activateDeviceIfNeeded to run.
            // This assumes activateDeviceIfNeeded will create a new token state.
            // If activateDeviceIfNeeded fails, we will proceed to clearTokenAndLogoutState.
            let previousTokenStateForLog = tokenState != nil // just for logging
            if tokenState != nil {
                 print("[AuthManager] Clearing existing token state before attempting silent activation.")
                 self.tokenState = nil 
                 self.isAuthenticated.send(false) // Reflect temporary state
            }


            try await activateDeviceIfNeeded(deviceId: deviceId) // This updates tokenState if successful
            
            if let newAccessToken = self.tokenState?.token.accessToken {
                print("[AuthManager] Silent activation successful. New access token obtained.")
                recordSilentActivationAttempt()
                return newAccessToken
            } else {
                print("[AuthManager] Silent activation attempted but resulted in no new token state. Previous token state existed: \(previousTokenStateForLog).")
                // If activateDeviceIfNeeded didn't throw but also didn't set a token, it's an issue.
                // This path should lead to logout.
                throw AuthError.activationFailed // Signal that activation didn't result in a token
            }
        } catch let activationError {
            print("[AuthManager] Silent device activation failed: \(activationError.localizedDescription)")
            // Ensure logout state if silent activation fails critically
            // await clearTokenAndLogoutState() // This is handled by the caller (getAccessToken)
            throw activationError // Rethrow to be handled by getAccessToken
        }
    }

    private func canAttemptSilentActivation() -> Bool {
        guard let lastAttempt = userDefaults.object(forKey: lastSilentActivationAttemptKey) as? Date else {
            print("[AuthManager] No record of last silent activation attempt. Allowed.")
            return true // Never attempted before
        }
        let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
        let allow = timeSinceLastAttempt > silentActivationCooldown
        print("[AuthManager] Time since last silent activation attempt: \(timeSinceLastAttempt)s. Cooldown: \(silentActivationCooldown)s. Allowed: \(allow)")
        return allow
    }

    private func recordSilentActivationAttempt() {
        userDefaults.set(Date(), forKey: lastSilentActivationAttemptKey)
        print("[AuthManager] Recorded silent activation attempt at \(Date()).")
    }

    public func getRefreshTokenForLogout() async throws -> String? {
        // This method provides the refresh token if available.
        // It's intended for use by LogoutUseCase or similar scenarios
        // where the refresh token is explicitly needed for an operation.
        guard let currentTokenState = tokenState else {
            print("[AuthManager getRefreshTokenForLogout] No token state available.")
            return nil // Or throw an error if a token is strictly expected
        }
        // Consider if the token being expired matters here.
        // For logout, usually the refresh token is sent regardless of access token expiry.
        return currentTokenState.token.refreshToken
    }
}

public enum AuthError: LocalizedError, Equatable {
    case noRefreshToken
    case refreshTokenFailed(Error?)
    case activationFailed
    case silentActivationCooldown
    case unknown(Error?)

    public var errorDescription: String? {
        switch self {
        case .noRefreshToken: return "リフレッシュトークンがありません。"
        case .refreshTokenFailed: return "トークンのリフレッシュに失敗しました。" // Underlying error not exposed to user directly here
        case .activationFailed: return "デバイスのアクティベーション試行に失敗しました。"
        case .silentActivationCooldown: return "サイレントアクティベーションはクールダウン中です。"
        case .unknown: return "不明な認証エラーです。"
        }
    }
    
    // Equatable conformance for AuthError without associated values
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.noRefreshToken, .noRefreshToken): return true
        case (.refreshTokenFailed, .refreshTokenFailed): return true // Note: Ignores associated error for Equatable
        case (.activationFailed, .activationFailed): return true
        case (.silentActivationCooldown, .silentActivationCooldown): return true
        case (.unknown, .unknown): return true // Note: Ignores associated error for Equatable
        default: return false
        }
    }
}

public enum UserFacingAuthError: LocalizedError {
    case activationFailed(Error)
    case refreshTokenFailed(Error)
    case logoutFailed(Error)
    case notAuthenticated
    case unknown(Error?)

    public var errorDescription: String? {
        switch self {
        case .activationFailed:
            return "デバイスのアクティベーションに失敗しました。通信環境を確認して再度お試しください。"
        case .refreshTokenFailed:
            return "セッションの更新に失敗しました。しばらくしてから再度お試しいただくか、再ログインしてください。"
        case .logoutFailed:
            return "ログアウト処理中にエラーが発生しました。"
        case .notAuthenticated:
            return "認証されていません。ログインしてください。"
        case .unknown:
            return "不明な認証エラーが発生しました。"
        }
    }
    
    public var underlyingError: Error? {
        switch self {
        case .activationFailed(let concreteError): return concreteError
        case .refreshTokenFailed(let concreteError): return concreteError
        case .logoutFailed(let concreteError): return concreteError
        case .unknown(let optionalError): return optionalError
        case .notAuthenticated: return nil
        }
    }
}
