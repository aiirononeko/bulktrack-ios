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

    @Published var userFacingError: UserFacingAuthError?

    private let authManager: AuthManagerProtocol
    private let deviceIdentifierService: DeviceIdentifierServiceProtocol

    init(container: DIContainer = .shared) {
        self.authManager = container.authManager
        self.deviceIdentifierService = container.deviceIdentifierService
    }

    /// アプリ起動時の初期化
    func initializeApp() {
        Task {
            do {
                let deviceId = deviceIdentifierService.getDeviceIdentifier()
                try await authManager.activateDeviceIfNeeded(deviceId: deviceId)
                
                if authManager.isAuthenticated.value {
                    print("[AppInitializer] App initialized. User is authenticated.")
                } else {
                    // This case might occur if activation was expected but didn't result in an authenticated state,
                    // though activateDeviceIfNeeded should throw if it fails to authenticate.
                    print("[AppInitializer] App initialized. User is NOT authenticated.")
                    // Potentially set a specific UserFacingAuthError if this state is unexpected after activation attempt.
                }
            } catch let error as UserFacingAuthError {
                print("[AppInitializer] Initialization failed with UserFacingAuthError: \(error.localizedDescription)")
                self.userFacingError = error
            } catch {
                print("[AppInitializer] Initialization failed with an unexpected error: \(error.localizedDescription)")
                self.userFacingError = .unknown(error)
            }
        }
    }
}

// Note: The main App struct (e.g., BulkTrackApp.swift) should observe 
// AppInitializer's userFacingError property and present an alert or other UI to the user.
