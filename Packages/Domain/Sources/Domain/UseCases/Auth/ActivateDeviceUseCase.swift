//
//  ActivateDeviceUseCase.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public protocol ActivateDeviceUseCaseProtocol {
    func execute(deviceId: String) async throws
}

public final class ActivateDeviceUseCase: ActivateDeviceUseCaseProtocol {
    private let authRepository: AuthRepository
    private let authManager: AuthManagerProtocol // AuthManager への依存を追加

    public init(authRepository: AuthRepository, authManager: AuthManagerProtocol) { // init に authManager を追加
        self.authRepository = authRepository
        self.authManager = authManager
    }

    public func execute(deviceId: String) async throws {
        let authToken = try await authRepository.activateDevice(deviceId: deviceId)
        // 取得したトークンを AuthManager に渡して処理させる
        // retrievedAt は AuthManager の loginWithNewToken のデフォルト値 (Date()) が使われる
        try await authManager.loginWithNewToken(authToken, retrievedAt: Date()) 
    }
}
