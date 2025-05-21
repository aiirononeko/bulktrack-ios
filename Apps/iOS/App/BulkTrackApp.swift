//
//  BulkTrackApp.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

@main
struct BulkTrackApp: App {
    // MARK: - State
    @StateObject private var appInitializer = AppInitializer()
//    @StateObject private var sessionManager = SessionManager()

    @State private var selection: Tab = .home
    @State private var showingAddWorkoutSheet = false

    // MARK: - Life‑cycle
    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Text("Hello, World!")
            .task {
                appInitializer.initializeApp()
            }
        }
    }

    // MARK: - Appearance
    private func configureAppearance() {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.secondarySystemBackground
        pageControl.currentPageIndicatorTintColor = UIColor.label
    }
}

// MARK: - Tab Definition
extension BulkTrackApp {
    enum Tab: Int, CaseIterable {
        case home, history, dummyCenter, menu, settings
    }
}
