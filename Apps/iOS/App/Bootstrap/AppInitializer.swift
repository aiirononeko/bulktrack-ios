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

    private let activationService: ActivationServiceProtocol
//    private let apiService: APIServiceProtocol

    init(container: DIContainer = .shared) {
        self.activationService = container.activationService
//        self.apiService        = container.apiService
    }

    /// アプリ起動時の初期化
    func initializeApp() {
        Task {
            do {
                try await activationService.activateDeviceIfNeeded()
//                try await apiService.bootstrap()
                print("[AppInitializer] Initialization succeeded")
            } catch {
                print("[AppInitializer] Initialization failed:", error)
            }
        }
    }
}
