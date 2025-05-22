import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
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
                // ここで dashboardData を使ってUIを構築できます
                // 例:
                Text("今週の総ボリューム: \(dashboardData.thisWeek.totalVolume, specifier: "%.0f")")
            }

            Button("ダッシュボードデータ取得") {
                viewModel.fetchDashboardData()
            }
            .padding()
        }
        .onAppear {
            print("[HomeView] onAppear - データを自動取得します。")
            viewModel.fetchDashboardData() // 画面表示時にデータを取得
        }
    }
}

// Preview Provider (Optional, for development)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // DIContainer.shared.makeHomeViewModel() を直接使えない場合があるため、
        // Preview用にモックのUseCaseやViewModelを準備することが推奨されます。
        // ここでは簡略化のため、実際のDIContainerを使いますが、
        // 実行環境によってはクラッシュする可能性があります。
        // 理想的には、モックのFetchDashboardUseCaseを作成し、それを使用します。
        
//        // モックUseCaseの例（実際にはDomainレイヤーに定義するか、Test Targetに置く）
//        class MockFetchDashboardUseCase: FetchDashboardUseCase {
//            func execute(span: String) async -> Result<DashboardEntity, AppError> {
//                // ダミーデータを返すか、エラーを返す
//                let dummyWeekPoint = WeekPointEntity(weekStart: Date(), totalVolume: 12345, avgSetVolume: 100, e1rmAvg: 80)
//                let dummyDashboard = DashboardEntity(
//                    thisWeek: dummyWeekPoint,
//                    lastWeek: dummyWeekPoint,
//                    trend: [dummyWeekPoint],
//                    muscleGroups: [],
//                    metrics: []
//                )
//                return .success(dummyDashboard)
//                // return .failure(.networkError(.noConnection))
//            }
//        }
//        
//        let mockViewModel = HomeViewModel(fetchDashboardUseCase: MockFetchDashboardUseCase())
//        return HomeView(際にはDomainレイヤーに定義するか、Test Targetに置く）
//        class MockFetchDashboardUseCase: FetchDashboardUseCase {
//            func execute(span: String) async -> Result<DashboardEntity, AppError> {
//                // ダミーデータを返すか、エラーを返す
//                let dummyWeekPoint = WeekPointEntity(weekStart: Date(), totalVolume: 12345, avgSetVolume: 100, e1rmAvg: 80)
//                let dummyDashboard = DashboardEntity(
//                    thisWeek: dummyWeekPoint,
//                    lastWeek: dummyWeekPoint,
//                    trend: [dummyWeekPoint],
//                    muscleGroups: [],
//                    metrics: []
//                )
//                return .success(dummyDashboard)
//                // return .failure(.networkError(.noConnection))
//            }
//        }
//        
//        let mockViewModel = HomeViewModel(fetchDashboardUseCase: MockFetchDashboardUseCase())
//        return HomeView(viewModel: mockViewModel)
    }
}
