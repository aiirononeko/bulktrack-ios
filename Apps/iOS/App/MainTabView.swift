import SwiftUI
import Domain // ExerciseEntity を使用するため

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
    @State private var showingAddSheet = false // 「トレーニング開始」シートの表示状態
    @State private var selectedExerciseForLog: ExerciseEntity? // 選択されたエクササイズ。これがnilでなければfullScreenCoverを表示

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
                    .frame(width: 44, height: 44)
                    .foregroundColor(colorScheme == .dark ? .white : .black) // アイコンの色
                    .background(colorScheme == .dark ? Color.black : Color.white) // ボタンの背景色
                    .clipShape(Circle())
                    .padding(.bottom, 1)
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingAddSheet) {
            StartWorkoutSheetView(
                onExerciseSelected: { exercise in
                    print("[MainTabView] Exercise selected: \(exercise.name)")
                    self.selectedExerciseForLog = exercise // これをセットすると fullScreenCover が item を検知する
                    self.showingAddSheet = false // シートを閉じる
                },
                viewModel: diContainer.makeStartWorkoutSheetViewModel()
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(item: $selectedExerciseForLog, onDismiss: {
            print("[MainTabView] WorkoutLogView dismissed (item became nil)")
        }) { exercise in // exercise は selectedExerciseForLog の non-nil の値
            // このクロージャは selectedExerciseForLog が nil でない場合にのみ呼び出される
            diContainer.makeWorkoutLogView(exerciseName: exercise.name, exerciseId: exercise.id)
        }
        .onAppear {
            updateTabBarAppearance(colorScheme: colorScheme)
        }
        .onChange(of: colorScheme) { newColorScheme in
            updateTabBarAppearance(colorScheme: newColorScheme)
        }
    }

    private func updateTabBarAppearance(colorScheme: ColorScheme) {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()

        if colorScheme == .dark {
            tabBarAppearance.backgroundColor = UIColor(white: 0.06, alpha: 1.0) // Even darker gray, very near black
            // You might want to adjust item colors for dark mode if needed
            // tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .lightGray
            // tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
            // tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .white
            // tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            // For light mode, use default or specify colors
            tabBarAppearance.backgroundColor = .white // Reverted to system default for light mode
            // tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .darkGray
            // tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.darkGray]
            // tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .black
            // tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        }

        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
