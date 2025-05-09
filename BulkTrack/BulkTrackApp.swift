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
        // UIPageControlの外観を設定 (ドットインジケータの色)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.lightGray.withAlphaComponent(0.6) // 非アクティブなドットの色
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.black // アクティブなドットの色
        // iOS 14以降では、背景スタイルも設定可能 (オプション)
        // if #available(iOS 14.0, *) {
        //     UIPageControl.appearance().backgroundStyle = .minimal // または .prominent, .automatic
        // }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("トレーニング履歴", systemImage: "clock.fill")
                    }

                AddPlaceholderView() // プラスボタンに対応するView
                    .tabItem {
                        Label("ワークアウト", systemImage: "plus.circle.fill")
                    }

                MenuView()
                    .tabItem {
                        Label("メニュー管理", systemImage: "list.bullet")
                    }

                SettingsView()
                    .tabItem {
                        Label("アプリ設定", systemImage: "gearshape.fill")
                    }
            }
            .accentColor(.black)
            .onAppear {
                // Viewが表示されたときに初期化処理を開始
                appInitializer.initializeApp()
            }
        }
    }
}
