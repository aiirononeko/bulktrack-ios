//
//  BulkTrackApp.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

@main
struct BulkTrackApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
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

                // TabViewの上部に表示するボーダー
                Rectangle()
                    .frame(height: 0.5) // ボーダーの太さ
                    .foregroundColor(Color.gray.opacity(0.5)) // ボーダーの色と透明度
                    .padding(.bottom, 50) // TabViewの高さに応じて調整 (約49-50pt)
            }
        }
    }
}
