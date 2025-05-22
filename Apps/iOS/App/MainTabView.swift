import SwiftUI

enum Tab: Hashable {
    case home
    case history
    case addPlaceholder // ダミーのタブ
    case articles
    case settings
}

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedTab: Tab = .home
    @State private var previousSelectedTab: Tab = .home // 直前のタブを保持
    @State private var showingAddSheet = false // シート表示用の状態変数

    private let diContainer = DIContainer.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: diContainer.makeHomeViewModel())
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }
                    .tag(Tab.home)

                HistoryView()
                    .tabItem {
                        Label("履歴", systemImage: "list.bullet.rectangle.fill")
                    }
                    .tag(Tab.history)

                // 中央のダミータブ
                Text("") // 空のビュー
                    .tabItem {
                        Label("", systemImage: "")
                    }
                    .tag(Tab.addPlaceholder)


                ArticlesView()
                    .tabItem {
                        Label("コラム", systemImage: "newspaper.fill")
                    }
                    .tag(Tab.articles)

                SettingsView()
                    .tabItem {
                        Label("アプリ設定", systemImage: "gearshape.fill")
                    }
                    .tag(Tab.settings)
            }
            .onChange(of: selectedTab) { newTab in
                if newTab == .addPlaceholder {
                    // ダミータブが選択されたらシートを表示し、タブ選択を元に戻す
                    showingAddSheet = true
                    // DispatchQueue.main.async を使って、現在の更新サイクルが完了した後に selectedTab を変更
                    DispatchQueue.main.async {
                        selectedTab = previousSelectedTab
                    }
                } else {
                    // 有効なタブが選択されたら previousSelectedTab を更新
                    previousSelectedTab = newTab
                }
            }
            .tint(colorScheme == .dark ? .white : .black)

            // フローティングボタン
            Button(action: {
                showingAddSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(colorScheme == .dark ? .white : .black) // アイコンの色
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.white) // ボタンの背景色
                    .clipShape(Circle())
                    .padding(.bottom, 4)
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGray6).ignoresSafeArea())
        .sheet(isPresented: $showingAddSheet) {
            // シートのコンテンツ
            VStack {
                Text("新しい記録を追加")
                    .font(.headline)
                    .padding()
                Spacer()
                Button("閉じる") {
                    showingAddSheet = false
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
    }
}
