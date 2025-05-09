//
//  BulkTrackApp.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

@main
struct BulkTrackApp: App {
    @StateObject private var appInitializer = AppInitializer()

    init() {
        print("BulkTrackApp struct initialized")
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }

                MenuView()
                    .tabItem {
                        Label("メニュー", systemImage: "list.bullet")
                    }

                AddPlaceholderView() // プラスボタンに対応するView
                    .tabItem {
                        Label("ワークアウト", systemImage: "plus.circle.fill")
                    }

                HistoryView()
                    .tabItem {
                        Label("履歴", systemImage: "clock.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill")
                    }
            }
            .onAppear {
                // Viewが表示されたときに初期化処理を開始
                appInitializer.initializeApp()
            }
        }
    }
}
