//
//  DIContainer.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import SwiftUI
import Domain

@MainActor
final class DIContainer {
    static let shared = DIContainer()

    let sessionSyncRepository: SessionSyncRepository
    let requestRecentExercisesUseCase: RequestRecentExercisesUseCaseProtocol

    private init() {
        let sessionSyncRepoInstance = WCSessionRelay() // WCSessionRelayがSessionSyncRepositoryに準拠していると仮定
        self.sessionSyncRepository = sessionSyncRepoInstance
        self.requestRecentExercisesUseCase = RequestRecentExercisesUseCase(sessionSyncRepository: sessionSyncRepoInstance)
    }
}
