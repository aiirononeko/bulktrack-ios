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
    @StateObject private var sessionManager = SessionManager() // SessionManager を StateObject として初期化
    @State private var selectedTabTag: Int = TabTag.home // TabView の selection にバインド
    @State private var isShowingAddWorkoutModal = false

    // タブのタグを定数として定義
    private enum TabTag {
        static let home = 0
        static let history = 1
        static let dummyCenter = 2 // 中央のダミースペース用のタグ
        static let menu = 3 
        static let settings = 4
    }

    init() {        
        // UIPageControlの外観を設定 (ドットインジケータの色)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.secondarySystemBackground // 非アクティブなドットの色をシステムカラーに変更
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label // アクティブなドットの色をシステムカラーに変更

        // Watch Connectivityのセットアップ
        WatchDataRelayService.shared.setupWatchConnectivity()
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) { 
                TabView(selection: $selectedTabTag) {
                    HomeView()
                        // .environmentObject(sessionManager) // 各タブのルートビューに渡す
                        .tabItem {
                            Label("ホーム", systemImage: "house.fill")
                        }
                        .tag(TabTag.home)
                    
                    HistoryView()
                        // .environmentObject(sessionManager)
                        .tabItem {
                            Label("トレーニング履歴", systemImage: "clock.fill")
                        }
                        .tag(TabTag.history)

                    // 中央のダミースペース (実質的にはタップさせない)
                    Text("") // または Spacer().frame(width: 0, height: 0) など
                        .tabItem {
                            // Labelを空にするか、非常に小さい透明な画像などを使う
                            // 実際にはこの上にカスタムボタンが重なる
                            Label("", systemImage: "square")
                        }
                        .tag(TabTag.dummyCenter)
                        .disabled(true) // タップを無効化

                    MenuView()
                        // .environmentObject(sessionManager)
                        .tabItem {
                            Label("メニュー管理", systemImage: "list.bullet")
                        }
                        .tag(TabTag.menu)

                    SettingsView()
                        // .environmentObject(sessionManager)
                        .tabItem {
                            Label("アプリ設定", systemImage: "gearshape.fill")
                        }
                        .tag(TabTag.settings)
                }
                .accentColor(Color.primary) // accentColorをprimaryに設定
                .environmentObject(sessionManager) // TabView全体、またはその親に一度だけ設定すればOK

                // カスタムプラスボタン
                Button {
                    isShowingAddWorkoutModal = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(uiColor: .systemBackground)) // 文字色をシステム背景色に
                        .padding(12)
                        .background(Circle().fill(Color.primary)) // 背景色をプライマリカラーに
                }
                // 一般的なタブバーのアイコン領域に合わせる
                // 安全マージンも考慮し、やや大きめの値を設定するか、GeometryReaderで動的に。
                // ここではiPhoneの標準的なタブバーの高さとセーフエリアを考慮した値を仮で設定します。
                // 実際の見た目を見ながら調整してください。
                .padding(.bottom, ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0) > 0 ? 30 : 10) // 下部のセーフエリアによって調整 (iOS 13+)
                .offset(y: 24) // 少し上にオフセットしてタブバーアイテムと高さを合わせる (お好みで調整)

            }
            .onAppear {
                appInitializer.initializeApp()
            }
            .sheet(isPresented: $isShowingAddWorkoutModal) {
                AddPlaceholderView()
                    .environmentObject(sessionManager) // モーダルにも渡す
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
