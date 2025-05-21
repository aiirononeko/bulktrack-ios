//
//  DIContainer.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Domain
import Data

@MainActor
final class DIContainer {
    static let shared = DIContainer()

    // MARK: - Services
    let watchConnectivityHandler: WCSessionRelay
    let deviceIdentifierService: DeviceIdentifierServiceProtocol
    let secureStorageService: SecureStorageServiceProtocol
    let authRepository: AuthRepository // Implemented by APIService
    let exerciseRepository: ExerciseRepository // Implemented by APIService
    let authManager: AuthManagerProtocol
    
    // let oldActivationService: ActivationServiceProtocol // Keep or remove based on its current use

    private init() {
        self.watchConnectivityHandler = WCSessionRelay()
        self.deviceIdentifierService = DeviceIdentifierService()
        self.secureStorageService = KeychainService()

        // APIService needs an accessTokenProvider. AuthManager provides this.
        // To break potential circular dependency during init:
        // 1. Create a placeholder/nil provider initially for APIService.
        // 2. Create AuthManager, which needs AuthRepository (APIService).
        // 3. Update APIService with the real provider from AuthManager.
        // OR: Make AuthManager's getAccessToken static or accessible without full init,
        // OR: Pass AuthManager instance to APIService later (less clean for init).

        // Simpler approach for now: AuthManager is created first, then APIService uses it.
        // This requires AuthManager not to depend on APIService *instance* in its own init,
        // but on the AuthRepository *protocol* which APIService will conform to.

        // Temporary instance of APIService for AuthManager init, if AuthManager needs it directly.
        // This is tricky. Let's define APIService such that its accessTokenProvider can be set post-init,
        // or make AuthManager take a factory/closure for AuthRepository.

        // Option: Initialize APIService without accessTokenProvider first, then set it.
        // This requires APIService's accessTokenProvider to be a `var`.
        // For now, let's assume APIService can take a nil provider and AuthManager will handle it.
        
        // APIService requires secureStorageService and an accessTokenProvider.
        // AuthManager requires authRepository (which is APIService).
        // This creates a circular dependency if not handled carefully.

        // Solution:
        // 1. Create a "bootstrap" APIService instance for AuthManager, without accessTokenProvider.
        //    AuthManager will use this for its authRepository needs (like activateDevice, refreshToken).
        //    These specific auth calls in APIService don't typically need an accessTokenProvider themselves.
        let bootstrapAPIService = APIService(
            secureStorageService: self.secureStorageService,
            accessTokenProvider: nil // Auth-specific calls in APIService don't need this.
        )

        // 2. Create AuthManager using the bootstrap APIService.
        let authManagerInstance = AuthManager(authRepository: bootstrapAPIService)
        self.authManager = authManagerInstance
        
        // 3. Create the main APIService instance for general repository use,
        //    now with a proper accessTokenProvider from the created AuthManager.
        let mainAPIService = APIService(
            secureStorageService: self.secureStorageService,
            accessTokenProvider: { [weak authManagerInstance] in // Closure captures the real AuthManager
                try await authManagerInstance?.getAccessToken() // Added try
            }
        )
        self.authRepository = mainAPIService // Use the fully configured APIService for AuthRepository
        self.exerciseRepository = mainAPIService

        // self.oldActivationService = ActivationService() // If still needed
    }
}
