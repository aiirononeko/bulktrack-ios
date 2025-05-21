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

    // Renamed to reflect its role on iOS: handling WCSession events.
    // The type is the concrete WCSessionRelay class for iOS.
    let watchConnectivityHandler: WCSessionRelay
    let activationService: ActivationServiceProtocol
    // TODO: Add other services like APIService here
    // let exerciseRepository: ExerciseRepository

    private init() {
        // Basic services
        self.activationService = ActivationService()
        self.watchConnectivityHandler = WCSessionRelay()
        // self.exerciseRepository = APIService() // Example for APIService
    }
}
