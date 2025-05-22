//
//  BulkTrackApp.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI
import Domain // DIContainer と HomeViewModel のために Domain をインポート

@main
struct BulkTrackApp: App {
    // MARK: - Dependencies
    private let diContainer = DIContainer.shared
    private let appInitializer: AppInitializer

    // MARK: - Life‑cycle
    init() {
        // AppInitializer を DIContainer インスタンスを渡して初期化
        self.appInitializer = AppInitializer(container: diContainer)
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: diContainer.makeHomeViewModel()) // HomeView を表示
            .task {
                await appInitializer.initializeApp() // await を追加
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
