//
//  AppInitializer.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import SwiftUI
import Domain
import Data

@MainActor
final class AppInitializer: ObservableObject {

    @Published var initializationState: ResultState<Void, AppError> = .idle

    private let activateDeviceUseCase: ActivateDeviceUseCaseProtocol
    private let deviceIdentifierService: DeviceIdentifierServiceProtocol
    private let authManager: AuthManagerProtocol // isAuthenticated を参照するために保持

    init(
        activateDeviceUseCase: ActivateDeviceUseCaseProtocol,
        deviceIdentifierService: DeviceIdentifierServiceProtocol,
        authManager: AuthManagerProtocol
    ) {
        self.activateDeviceUseCase = activateDeviceUseCase
        self.deviceIdentifierService = deviceIdentifierService
        self.authManager = authManager
    }

    /// アプリ起動時の初期化
    func initializeApp() {
        // // TabBarの外観をシステム標準に設定
         let appearance = UITabBarAppearance()
         appearance.configureWithOpaqueBackground()
         UITabBar.appearance().standardAppearance = appearance
         if #available(iOS 15.0, *) {
             UITabBar.appearance().scrollEdgeAppearance = appearance
         }

        guard initializationState.isIdle || initializationState.failureError != nil else {
            // Already loading or successfully initialized
            return
        }
        initializationState = .loading
        Task {
            do {                
                let deviceId = deviceIdentifierService.getDeviceIdentifier()

                if !authManager.isAuthenticated.value {
                    print("[AppInitializer] User not authenticated, attempting activation via UseCase.")
                    try await activateDeviceUseCase.execute(deviceId: deviceId)
                    print("[AppInitializer] activateDeviceUseCase.execute completed.")
                } else {
                    print("[AppInitializer] User already authenticated.")
                }
                                
                if authManager.isAuthenticated.value { // AuthManager の状態が更新されたことを期待して再度確認
                    print("[AppInitializer] App initialized. User is authenticated.")
                    self.initializationState = .success(())
                } else {
                    print("[AppInitializer] App initialized. User is NOT authenticated. This might be an issue if activation was expected.")
                    // Consider if this state should be an error.
                    // If activation was attempted and didn't make isAuthenticated true, it's a failure.
                    // For now, if it reaches here without throwing, but not authenticated, treat as a specific auth error.
                    self.initializationState = .failure(.authenticationError(.activationFailed("認証状態になりませんでした。")))
                }
            } catch let error as AppError {
                print("[AppInitializer] Initialization failed with AppError: \(error.localizedDescription)")
                self.initializationState = .failure(error)
            } catch let error as UserFacingAuthError { // Keep catching UserFacingAuthError for now, map to AppError
                print("[AppInitializer] Initialization failed with UserFacingAuthError: \(error.localizedDescription)")
                // Map UserFacingAuthError to AppError
                // This mapping logic might need to be more sophisticated
                switch error {
                case .activationFailed(let underlying):
                    self.initializationState = .failure(.authenticationError(.activationFailed(underlying.localizedDescription)))
                case .refreshTokenFailed(let underlying): // Should not happen here ideally
                    self.initializationState = .failure(.authenticationError(.refreshTokenFailed(underlying.localizedDescription)))
                default:
                    self.initializationState = .failure(.unknownError(error.localizedDescription))
                }
            }
            catch {
                print("[AppInitializer] Initialization failed with an unexpected error: \(error.localizedDescription)")
                self.initializationState = .failure(.unknownError(error.localizedDescription))
            }
        }
    }
}

// Note: The main App struct (e.g., BulkTrackApp.swift) should observe 
// AppInitializer's initializationState property and present an alert or other UI to the user.
