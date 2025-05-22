//
//  LogoutUseCase.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public protocol LogoutUseCaseProtocol {
    func execute() async throws
}

public final class LogoutUseCase: LogoutUseCaseProtocol {
    private let authRepository: AuthRepository
    private let authManager: AuthManagerProtocol

    public init(authRepository: AuthRepository, authManager: AuthManagerProtocol) {
        self.authRepository = authRepository
        self.authManager = authManager
    }

    public func execute() async throws {
        guard let refreshToken = try await authManager.getRefreshTokenForLogout() else {
            // リフレッシュトークンがない場合はログアウト済み、または異常系
            // ここではエラーとせず、何もせずに終了する（既にログアウトされている可能性）
            // あるいは、エラーをthrowして呼び出し元に処理を委ねる
            // throw AuthError.noRefreshToken // AuthErrorはAuthManager.swiftで定義されている
            print("[LogoutUseCase] No refresh token found, assuming already logged out or unrecoverable state.")
            return
        }
        try await authRepository.logout(using: refreshToken)
    }
}
