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
    @StateObject private var appInitializer = DIContainer.shared.appInitializer // DIContainer から取得し @StateObject で保持

    // MARK: - Life‑cycle
    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            switch appInitializer.initializationState {
            case .idle, .loading:
                ProgressView("アプリケーションを準備中...")
                    .task { // ProgressView が表示されたときに一度だけ実行
                        if appInitializer.initializationState.isIdle { // 既に実行中でなければ
                           await appInitializer.initializeApp()
                        }
                    }
            case .success:
                MainTabView()
                    .environmentObject(appInitializer) // MainTabView 以下で必要なら渡す
            case .failure(let error):
                VStack {
                    Text("アプリケーションの起動に失敗しました")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                    Button("再試行") {
                        Task {
                            await appInitializer.initializeApp()
                        }
                    }
                    .padding()
                }
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
