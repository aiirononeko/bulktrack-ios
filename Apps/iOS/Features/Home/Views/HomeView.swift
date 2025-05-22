import SwiftUI
// import Domain // viewModelがDomainの型に依存していなければ不要になる可能性

struct HomeView: View {
    // AppInitializerへの参照は不要になる
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Hello, World!")
                    .font(.largeTitle)
                .padding()

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
            .frame(maxWidth: .infinity, maxHeight: .infinity) // VStackを画面全体に広げる
            .background(Color(uiColor: .systemGray6).ignoresSafeArea()) // 背景色を設定し、セーフエリアを無視
            .navigationTitle("ホーム")
            .onAppear {
                print("[HomeView] onAppear - データを自動取得します。")
                viewModel.fetchDashboardData() // 画面表示時にデータを取得
            }
        }
    }
}

// Preview Provider (Optional, for development)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {}
}
