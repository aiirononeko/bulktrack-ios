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
    let workoutHistoryRepository: WorkoutHistoryRepository
    
    // MARK: - Background & Persistence Services
    let backgroundTimerService: BackgroundTimerServiceProtocol
    let timerPersistenceService: TimerPersistenceServiceProtocol
    let liveActivityService: LiveActivityServiceProtocol
    
    // MARK: - Use Cases
    let deviceIdentificationUseCase: DeviceIdentificationUseCase
    let activateDeviceUseCase: ActivateDeviceUseCaseProtocol
    let logoutUseCase: LogoutUseCaseProtocol
    let fetchDashboardUseCase: FetchDashboardUseCase
    let handleRecentExercisesRequestUseCase: HandleRecentExercisesRequestUseCaseProtocol
    let fetchRecentExercisesUseCase: FetchRecentExercisesUseCaseProtocol
    let fetchAllExercisesUseCase: FetchAllExercisesUseCaseProtocol
    let createSetUseCase: CreateSetUseCaseProtocol
    
    // MARK: - Workout History Use Cases
    let getWorkoutHistoryUseCase: GetWorkoutHistoryUseCaseProtocol
    let saveWorkoutSetUseCase: SaveWorkoutSetUseCaseProtocol
    
    // MARK: - Timer Use Cases
    let intervalTimerUseCase: IntervalTimerUseCaseProtocol
    let timerNotificationUseCase: TimerNotificationUseCaseProtocol
    let globalTimerService: GlobalTimerServiceProtocol
    
    // MARK: - Singleton ViewModels
    private lazy var _globalTimerViewModel = GlobalTimerViewModel(
        globalTimerService: globalTimerService,
        exerciseRepository: exerciseRepository
    )
    
    let appInitializer: AppInitializer

    private init() {
        print("[DIContainer] Initializing with background timer and Live Activity support...")
        
        // 1. Initialize basic services
        self.deviceIdentifierService = EnhancedDeviceIdentifierService()
        self.secureStorageService = KeychainService()
        
        // 2. Initialize background & persistence services
        self.backgroundTimerService = BackgroundTimerService()
        self.timerPersistenceService = TimerPersistenceService()
        self.liveActivityService = LiveActivityService()
        
        // 3. Initialize CoreData stack
        self.persistentContainer = PersistentContainer.shared
        
        // 4. Initialize cache repositories
        self.exerciseCacheRepository = ExerciseCacheRepository(persistentContainer: self.persistentContainer)
        self.recentExerciseCacheRepository = RecentExerciseCacheRepository(persistentContainer: self.persistentContainer)
        self.cacheInvalidationService = CacheInvalidationService(
            exerciseCacheRepository: self.exerciseCacheRepository,
            recentExerciseCacheRepository: self.recentExerciseCacheRepository
        )
        
        // 4.1. Initialize workout history repository
        self.workoutHistoryRepository = CoreDataWorkoutHistoryRepository(persistentContainer: self.persistentContainer)

        // 5. Create the APIService instance first, with accessTokenProvider initially nil.
        let apiServiceInstance = APIService(
            secureStorageService: self.secureStorageService,
            accessTokenProvider: nil // Will be set later
        )
        self.authRepository = apiServiceInstance
        self.dashboardRepository = apiServiceInstance

        // 6. Create CachedExerciseRepository with APIService and cache repositories
        let cachedExerciseRepository = CachedExerciseRepository(
            apiService: apiServiceInstance,
            exerciseCacheRepository: self.exerciseCacheRepository,
            recentExerciseCacheRepository: self.recentExerciseCacheRepository,
            cacheInvalidationService: self.cacheInvalidationService
        )
        self.exerciseRepository = cachedExerciseRepository

        // 7. Create AuthManager, injecting the APIService instance as its AuthRepository.
        let authManagerInstance = AuthManager(authRepository: apiServiceInstance, deviceIdentifierService: self.deviceIdentifierService)
        self.authManager = authManagerInstance
        
        // 8. Now that AuthManager instance exists, set the accessTokenProvider on the APIService instance.
        apiServiceInstance.setAccessTokenProvider { [weak authManagerInstance] in
            try await authManagerInstance?.getAccessToken()
        }

        // 9. Initialize UseCases with cached repository
        self.deviceIdentificationUseCase = DeviceIdentificationUseCase(deviceIdentifierService: self.deviceIdentifierService)
        self.activateDeviceUseCase = ActivateDeviceUseCase(authRepository: apiServiceInstance, authManager: authManagerInstance)
        self.logoutUseCase = LogoutUseCase(authRepository: apiServiceInstance, authManager: authManagerInstance)
        self.fetchDashboardUseCase = DefaultFetchDashboardUseCase(repository: apiServiceInstance)
        self.handleRecentExercisesRequestUseCase = HandleRecentExercisesRequestUseCase(exerciseRepository: cachedExerciseRepository)
        self.fetchRecentExercisesUseCase = FetchRecentExercisesUseCase(exerciseRepository: cachedExerciseRepository)
        self.fetchAllExercisesUseCase = FetchAllExercisesUseCase(exerciseRepository: cachedExerciseRepository)
        self.createSetUseCase = CreateSetUseCase(setRepository: apiServiceInstance)
        
        // 9.1. Initialize Workout History UseCases
        self.getWorkoutHistoryUseCase = GetWorkoutHistoryUseCase(workoutHistoryRepository: self.workoutHistoryRepository)
        self.saveWorkoutSetUseCase = SaveWorkoutSetUseCase(
            setRepository: apiServiceInstance,
            workoutHistoryRepository: self.workoutHistoryRepository
        )
        
        // 9.2. Initialize Timer UseCases with background support
        self.timerNotificationUseCase = TimerNotificationUseCase()
        self.intervalTimerUseCase = IntervalTimerUseCase(
            initialState: .defaultTimer(),
            notificationUseCase: self.timerNotificationUseCase
        )
        
        // 9.3. Initialize Global Timer Service with background, persistence & Live Activity support
        self.globalTimerService = GlobalTimerService(
            intervalTimerUseCase: self.intervalTimerUseCase,
            notificationUseCase: self.timerNotificationUseCase,
            backgroundTimerService: self.backgroundTimerService,
            persistenceService: self.timerPersistenceService,
            liveActivityService: self.liveActivityService
        )
        
        // 10. Initialize WCSessionRelay with the cached ExerciseRepository
        self.watchConnectivityHandler = WCSessionRelay(handleRecentExercisesRequestUseCase: self.handleRecentExercisesRequestUseCase)

        // 11. Initialize AppInitializer
        self.appInitializer = AppInitializer(
            activateDeviceUseCase: self.activateDeviceUseCase,
            deviceIdentifierService: self.deviceIdentifierService,
            authManager: self.authManager,
            globalTimerService: self.globalTimerService,
            timerNotificationUseCase: self.timerNotificationUseCase
        )
        
        print("[DIContainer] Initialization complete with background timer and Live Activity support.")
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
    
    func makeWorkoutLogView(exercise: ExerciseEntity) -> WorkoutLogView {
        return WorkoutLogView(
            exercise: exercise,
            saveWorkoutSetUseCase: saveWorkoutSetUseCase,
            getWorkoutHistoryUseCase: getWorkoutHistoryUseCase,
            globalTimerViewModel: _globalTimerViewModel // シングルトンインスタンスを使用
        )
    }
    
    func makeIntervalTimerViewModel(exerciseId: UUID? = nil) -> IntervalTimerViewModel {
        IntervalTimerViewModel(
            intervalTimerUseCase: intervalTimerUseCase,
            notificationUseCase: timerNotificationUseCase,
            exerciseId: exerciseId
        )
    }
    
    func makeGlobalTimerViewModel() -> GlobalTimerViewModel {
        return _globalTimerViewModel // 常に同じインスタンスを返す
    }
    
    // MARK: - Background Timer Status
    var backgroundAppRefreshStatus: BackgroundAppRefreshStatus {
        backgroundTimerService.checkBackgroundAppRefreshStatus()
    }
    
    func requestBackgroundProcessingPermission() {
        backgroundTimerService.requestBackgroundProcessingPermission()
    }
}
