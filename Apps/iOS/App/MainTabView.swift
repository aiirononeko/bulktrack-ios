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
    @StateObject private var globalTimerViewModel = DIContainer.shared.makeGlobalTimerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 上部のグローバルタイマーバー（WorkoutLogView表示時以外）
            if selectedExerciseForLog == nil {
                TopTimerBarView(globalTimerViewModel: globalTimerViewModel)
                    .animation(.easeInOut(duration: 0.3), value: globalTimerViewModel.hasActiveTimer)
            }
            
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
                .tint(.accentColor)

                // フローティングボタン
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(floatingButtonIconColor)
                        .background(floatingButtonBackgroundColor)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 1)
                }
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
            diContainer.makeWorkoutLogView(exercise: exercise)
        }
        .onAppear {
            updateTabBarAppearance(colorScheme: colorScheme)
        }
        .onChange(of: colorScheme) { newColorScheme in
            updateTabBarAppearance(colorScheme: newColorScheme)
        }
        .onChange(of: globalTimerViewModel.shouldNavigateToExercise) { exercise in
            // タイマーからエクササイズ画面への遷移要求
            if let exercise = exercise {
                print("[MainTabView] Navigating to exercise from timer: \(exercise.name)")
                selectedExerciseForLog = exercise
                
                // ナビゲーション後にフラグをクリア
                DispatchQueue.main.async {
                    globalTimerViewModel.shouldNavigateToExercise = nil
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var floatingButtonIconColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var floatingButtonBackgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    private func updateTabBarAppearance(colorScheme: ColorScheme) {
        DispatchQueue.main.async {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()

            if colorScheme == .dark {
                tabBarAppearance.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
                
                // ダークモード時のタブアイテム色設定
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
                tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                
                // インラインレイアウト（横向き時）の色設定
                tabBarAppearance.inlineLayoutAppearance.normal.iconColor = UIColor.lightGray
                tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
                tabBarAppearance.inlineLayoutAppearance.selected.iconColor = UIColor.white
                tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                
                // コンパクトレイアウトの色設定
                tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.lightGray
                tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
                tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.white
                tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                
            } else {
                tabBarAppearance.backgroundColor = UIColor.white
                
                // ライトモード時のタブアイテム色設定
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.darkGray
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.darkGray]
                tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
                tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
                
                // インラインレイアウトの色設定
                tabBarAppearance.inlineLayoutAppearance.normal.iconColor = UIColor.darkGray
                tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.darkGray]
                tabBarAppearance.inlineLayoutAppearance.selected.iconColor = UIColor.black
                tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
                
                // コンパクトレイアウトの色設定
                tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.darkGray
                tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.darkGray]
                tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.black
                tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
            }

            // 現在表示されているすべてのタブバーに適用
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                applyTabBarAppearanceToHierarchy(view: window, appearance: tabBarAppearance)
            }
            
            // 新しいタブバーのデフォルト設定
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
    // タブバーの階層を辿って既存のタブバーに設定を適用
    private func applyTabBarAppearanceToHierarchy(view: UIView, appearance: UITabBarAppearance) {
        if let tabBar = view as? UITabBar {
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
        
        for subview in view.subviews {
            applyTabBarAppearanceToHierarchy(view: subview, appearance: appearance)
        }
    }
}
