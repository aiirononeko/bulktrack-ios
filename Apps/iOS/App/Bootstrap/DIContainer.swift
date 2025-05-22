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
    let dashboardRepository: DashboardRepository // Implemented by APIService
    let authManager: AuthManagerProtocol
    let activateDeviceUseCase: ActivateDeviceUseCaseProtocol
    let logoutUseCase: LogoutUseCaseProtocol
    let fetchDashboardUseCase: FetchDashboardUseCase // Added
    let handleRecentExercisesRequestUseCase: HandleRecentExercisesRequestUseCaseProtocol // Added
    let appInitializer: AppInitializer // AppInitializer を追加
    
    // let oldActivationService: ActivationServiceProtocol // Keep or remove based on its current use

    private init() {
        print("[DIContainer] Initializing...") // Added log
        // self.watchConnectivityHandler = WCSessionRelay() // Old initialization
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
        
        // APIService needs an accessTokenProvider. AuthManager provides this.
        // AuthManager needs an AuthRepository (which is APIService).
        // This creates a circular dependency that can be resolved by setting the provider post-init.

        // 1. Create the APIService instance first, with accessTokenProvider initially nil.
        let apiServiceInstance = APIService(
            secureStorageService: self.secureStorageService,
            accessTokenProvider: nil // Will be set later
        )
        self.authRepository = apiServiceInstance
        self.exerciseRepository = apiServiceInstance
        self.dashboardRepository = apiServiceInstance // Added: APIService conforms to DashboardRepository

        // 2. Create AuthManager, injecting the APIService instance as its AuthRepository.
        let authManagerInstance = AuthManager(authRepository: apiServiceInstance, deviceIdentifierService: self.deviceIdentifierService)
        self.authManager = authManagerInstance
        
        // 3. Now that AuthManager instance exists, set the accessTokenProvider on the APIService instance.
        //    This closure captures the authManagerInstance.
        apiServiceInstance.setAccessTokenProvider { [weak authManagerInstance] in
            try await authManagerInstance?.getAccessToken()
        }

        // 4. Initialize UseCases
        self.activateDeviceUseCase = ActivateDeviceUseCase(authRepository: apiServiceInstance, authManager: authManagerInstance) // authManagerInstance を追加
        self.logoutUseCase = LogoutUseCase(authRepository: apiServiceInstance, authManager: authManagerInstance)
        self.fetchDashboardUseCase = DefaultFetchDashboardUseCase(repository: apiServiceInstance) // Added
        self.handleRecentExercisesRequestUseCase = HandleRecentExercisesRequestUseCase(exerciseRepository: apiServiceInstance) // Added
        
        // 5. Initialize WCSessionRelay with the correct ExerciseRepository (apiServiceInstance)
        self.watchConnectivityHandler = WCSessionRelay(handleRecentExercisesRequestUseCase: self.handleRecentExercisesRequestUseCase)

        // 6. Initialize AppInitializer (depends on other services like AuthManager, DeviceIdentifierService)
        self.appInitializer = AppInitializer(
            activateDeviceUseCase: self.activateDeviceUseCase, // activateDeviceUseCase を再度追加
            deviceIdentifierService: self.deviceIdentifierService,
            authManager: self.authManager
        )

        // self.oldActivationService = ActivationService() // If still needed
    }

    // MARK: - ViewModel Factory Methods
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(fetchDashboardUseCase: fetchDashboardUseCase)
    }
}
