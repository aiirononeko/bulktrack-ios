import SwiftUI

enum Tab {
    case home
    case history
    case articles
    case settings
}

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme // 現在のカラースキームを取得
    @State private var selectedTab: Tab = .home
    private let diContainer = DIContainer.shared // HomeViewModel のために DIContainer を利用

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: diContainer.makeHomeViewModel())
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(Tab.home)

            HistoryView() // 後で作成
                .tabItem {
                    Label("トレーニング履歴", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(Tab.history)

            ArticlesView() // 後で作成
                .tabItem {
                    Label("コラム", systemImage: "newspaper.fill")
                }
                .tag(Tab.articles)

            SettingsView() // 後で作成
                .tabItem {
                    Label("アプリ設定", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(colorScheme == .dark ? .white : .black) // ダークモード時は白、ライトモード時は黒に設定
        .frame(maxWidth: .infinity, maxHeight: .infinity) // ビューを画面全体に広げる
        .background(Color(uiColor: .systemGray6).ignoresSafeArea()) // セーフエリアを無視して背景色を設定
    }
}
