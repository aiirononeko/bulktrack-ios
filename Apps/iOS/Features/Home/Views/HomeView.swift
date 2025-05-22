import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var selectedTab = 0
    private let tabTitles = ["今週のボリューム", "週次ボリュームの推移", "週次平均RMの推移"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    CurrentWeekVolumeView(viewModel: viewModel)
                        .tag(0)
                    WeeklyVolumeTrendView() // ViewModelを渡す必要があれば後で修正
                        .tag(1)
                    WeeklyAverageRMView() // ViewModelを渡す必要があれば後で修正
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 標準のインジケータは非表示
                .frame(height: UIScreen.main.bounds.height * 4 / 9)
                .background(colorScheme == .dark ? Color.black : Color.white)

                // 自作ドットインジケータ
                DotIndicatorView(count: tabTitles.count, selectedIndex: $selectedTab)
                    .padding(.vertical, 18) // インジケータの上下にパディング

                // 残りのスペースに既存のコンテンツを表示
                VStack {
                    if viewModel.isLoading {
                        ProgressView("データを取得中...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("エラー: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if let dashboardData = viewModel.dashboardData {
                        Text("今週の総ボリューム: \(dashboardData.thisWeek.totalVolume, specifier: "%.0f")")
                    }

                    Button("ダッシュボードデータ取得") {
                        viewModel.fetchDashboardData()
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 残りのスペースを埋める
            }
            .background((colorScheme == .dark ? .black : Color(uiColor: .systemGray6)).ignoresSafeArea())
            .navigationTitle("ホーム")
            .onAppear {
                print("[HomeView] onAppear - データを自動取得します。")
                viewModel.fetchDashboardData()
            }
        }
    }
}

// Preview Provider (Optional, for development)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
    }
}
