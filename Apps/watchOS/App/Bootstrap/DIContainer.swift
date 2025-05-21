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

    private init() {
        self.sessionSyncRepository = WCSessionRelay()
    }
}
