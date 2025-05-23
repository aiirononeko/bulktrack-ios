//
//  DIContainer.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
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
    let exerciseRepository: CacheableExerciseRepository // Implemented by CachedExerciseRepository
    let dashboardRepository: DashboardRepository // Implemented by APIService
    let authManager: AuthManagerProtocol
    
    // MARK: - Cache Services
    let persistentContainer: PersistentContainer
    let exerciseCacheRepository: ExerciseCacheRepositoryProtocol
    let recentExerciseCacheRepository: RecentExerciseCacheRepositoryProtocol
    let cacheInvalidationService: CacheInvalidationServiceProtocol
    
    // MARK: - Use Cases
    let activateDeviceUseCase: ActivateDeviceUseCaseProtocol
    let logoutUseCase: LogoutUseCaseProtocol
    let fetchDashboardUseCase: FetchDashboardUseCase
    let handleRecentExercisesRequestUseCase: HandleRecentExercisesRequestUseCaseProtocol
    let fetchRecentExercisesUseCase: FetchRecentExercisesUseCaseProtocol
    let fetchAllExercisesUseCase: FetchAllExercisesUseCaseProtocol
    let createSetUseCase: CreateSetUseCaseProtocol
    let appInitializer: AppInitializer

    private init() {
        print("[DIContainer] Initializing with cache support...")
        
        // 1. Initialize basic services
        self.deviceIdentifierService = DeviceIdentifierService()
        self.secureStorageService = KeychainService()
        
        // 2. Initialize CoreData stack
        self.persistentContainer = PersistentContainer.shared
        
        // 3. Initialize cache repositories
        self.exerciseCacheRepository = ExerciseCacheRepository(persistentContainer: self.persistentContainer)
        self.recentExerciseCacheRepository = RecentExerciseCacheRepository(persistentContainer: self.persistentContainer)
        self.cacheInvalidationService = CacheInvalidationService(
            exerciseCacheRepository: self.exerciseCacheRepository,
            recentExerciseCacheRepository: self.recentExerciseCacheRepository
        )

        // 4. Create the APIService instance first, with accessTokenProvider initially nil.
        let apiServiceInstance = APIService(
            secureStorageService: self.secureStorageService,
            accessTokenProvider: nil // Will be set later
        )
        self.authRepository = apiServiceInstance
        self.dashboardRepository = apiServiceInstance

        // 5. Create CachedExerciseRepository with APIService and cache repositories
        let cachedExerciseRepository = CachedExerciseRepository(
            apiService: apiServiceInstance,
            exerciseCacheRepository: self.exerciseCacheRepository,
            recentExerciseCacheRepository: self.recentExerciseCacheRepository,
            cacheInvalidationService: self.cacheInvalidationService
        )
        self.exerciseRepository = cachedExerciseRepository

        // 6. Create AuthManager, injecting the APIService instance as its AuthRepository.
        let authManagerInstance = AuthManager(authRepository: apiServiceInstance, deviceIdentifierService: self.deviceIdentifierService)
        self.authManager = authManagerInstance
        
        // 7. Now that AuthManager instance exists, set the accessTokenProvider on the APIService instance.
        apiServiceInstance.setAccessTokenProvider { [weak authManagerInstance] in
            try await authManagerInstance?.getAccessToken()
        }

        // 8. Initialize UseCases with cached repository
        self.activateDeviceUseCase = ActivateDeviceUseCase(authRepository: apiServiceInstance, authManager: authManagerInstance)
        self.logoutUseCase = LogoutUseCase(authRepository: apiServiceInstance, authManager: authManagerInstance)
        self.fetchDashboardUseCase = DefaultFetchDashboardUseCase(repository: apiServiceInstance)
        self.handleRecentExercisesRequestUseCase = HandleRecentExercisesRequestUseCase(exerciseRepository: cachedExerciseRepository)
        self.fetchRecentExercisesUseCase = FetchRecentExercisesUseCase(exerciseRepository: cachedExerciseRepository)
        self.fetchAllExercisesUseCase = FetchAllExercisesUseCase(exerciseRepository: cachedExerciseRepository)
        self.createSetUseCase = CreateSetUseCase(setRepository: apiServiceInstance)
        
        // 9. Initialize WCSessionRelay with the cached ExerciseRepository
        self.watchConnectivityHandler = WCSessionRelay(handleRecentExercisesRequestUseCase: self.handleRecentExercisesRequestUseCase)

        // 10. Initialize AppInitializer
        self.appInitializer = AppInitializer(
            activateDeviceUseCase: self.activateDeviceUseCase,
            deviceIdentifierService: self.deviceIdentifierService,
            authManager: self.authManager
        )
        
        print("[DIContainer] Initialization complete with cache support.")
    }

    // MARK: - ViewModel Factory Methods
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(fetchDashboardUseCase: fetchDashboardUseCase)
    }

    func makeStartWorkoutSheetViewModel() -> StartWorkoutSheetViewModel {
        StartWorkoutSheetViewModel(
            fetchRecentExercisesUseCase: fetchRecentExercisesUseCase,
            fetchAllExercisesUseCase: fetchAllExercisesUseCase
        )
    }
    
    func makeWorkoutLogView(exerciseName: String, exerciseId: UUID) -> WorkoutLogView {
        WorkoutLogView(
            exerciseName: exerciseName,
            exerciseId: exerciseId,
            createSetUseCase: createSetUseCase
        )
    }
}
