import Foundation
import Combine // ObservableObjectと@Publishedのために必要

// APIServiceから取得するDashboardResponse.CurrentWeekSummaryをViewに渡すためのViewModel
class HomeViewModel: ObservableObject {
    @Published var currentWeekSummary: CurrentWeekSummary? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>() // Combineの購読管理用

    init() {
        // fetchDashboardData() // init時に自動で取得開始するか、ViewのonAppearで呼ぶかを選択
    }

    func fetchDashboardData(period: String = "4w") { // デフォルトピリオドを設定できるようにする
        isLoading = true
        errorMessage = nil
        currentWeekSummary = nil // 以前のデータをクリア

        apiService.fetchDashboard(period: period) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async { // UI更新はメインスレッドで
                self.isLoading = false
                switch result {
                case .success(let dashboardResponse):
                    self.currentWeekSummary = dashboardResponse.currentWeekSummary
                    print("HomeViewModel: Successfully fetched and updated currentWeekSummary.")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("HomeViewModel: Failed to fetch dashboard data: \(error.localizedDescription)")
                    // APIErrorのより詳細なハンドリングも可能
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "認証エラーが発生しました。再度お試しいただくか、アプリを再起動してください。"
                        // 他のエラーケースに応じたメッセージを設定
                        default:
                            self.errorMessage = "データの取得に失敗しました: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    // API ServiceのfetchDashboardがResult<DashboardResponse, Error>を返すので、
    // CurrentWeekSummaryだけでなく、他の情報もViewModelで保持できるように
    // DashboardResponse全体を@Publishedで持つことも検討できる。
    // @Published var dashboardResponse: DashboardResponse? = nil
    // その場合、View側では viewModel.dashboardResponse?.currentWeekSummary のようにアクセスする。
}

// このViewModelで使うためには、CurrentWeekSummaryとMuscleVolumeItemが
// APIService.swift以外からもアクセスできるようにpublicになっているか、
// または同じモジュール内にある必要がある。
// APIService.swift内の定義をpublicにするか、専用のModelsフォルダに移動して
// ターゲットメンバーシップを適切に設定することを推奨。
// 今回はAPIService.swiftと同じターゲットにあると仮定して進める。
