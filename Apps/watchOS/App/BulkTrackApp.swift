//
//  BulkTrackApp.swift
//  BulkTrack Watch App
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

@main
struct BulkTrackWatchApp: App {
    @StateObject private var initializer = WatchAppInitializer()
    
    var body: some Scene {
        WindowGroup {
            RecentExercisesView()
                .environmentObject(initializer)
                .task {
                    await initializer.initializeApp()
                }
        }
    }
}
