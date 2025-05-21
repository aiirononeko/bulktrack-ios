//
//  WatchAppInitializer.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import SwiftUI

@MainActor
final class WatchAppInitializer: ObservableObject {

    private let container: DIContainer

    init(container: DIContainer = .shared) {
        self.container = container
        setupWatchConnectivity()
    }

    /// Performs activation check, token refresh, prefills caches, etc.
    func initializeApp() async {
    }

    // MARK: – WCSession configuration
    private func setupWatchConnectivity() {
        (container.sessionSyncRepository as? WCSessionRelay)?.activate()
    }
}
