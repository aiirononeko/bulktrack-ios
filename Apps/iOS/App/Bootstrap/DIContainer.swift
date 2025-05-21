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

    let sessionSyncRepository: SessionSyncRepository
    let activationService: ActivationServiceProtocol

    private init() {
        // 基本サービス
        self.activationService = ActivationService()
        self.sessionSyncRepository = WCSessionRelay()
    }
}
