//
//  ActivateDeviceUseCase.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public protocol ActivateDeviceUseCaseProtocol {
    func execute(deviceId: String) async throws -> AuthToken
}

public final class ActivateDeviceUseCase: ActivateDeviceUseCaseProtocol {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute(deviceId: String) async throws -> AuthToken {
        return try await authRepository.activateDevice(deviceId: deviceId)
    }
}
