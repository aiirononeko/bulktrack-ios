import Foundation
import Combine // ObservableObjectと@Publishedのために必要

// APIServiceから取得するDashboardResponse.CurrentWeekSummaryをViewに渡すためのViewModel
class HomeViewModel: ObservableObject {
    @Published var dashboardData: DashboardResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>() // Combineの購読管理用

    init() {
        // fetchDashboardData() // init時に自動で取得開始するか、ViewのonAppearで呼ぶかを選択
    }

    func fetchDashboardData(period: String = "4w") { // APIのデフォルトは "1w" だが、ViewModelでは "4w" を維持
        isLoading = true
        errorMessage = nil
        dashboardData = nil // 以前のデータをクリア

        apiService.fetchDashboard(period: period) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async { // UI更新はメインスレッドで
                self.isLoading = false
                switch result {
                case .success(let newDashboardData):
                    self.dashboardData = newDashboardData // 新しいDashboardResponse全体を格納
                    print("HomeViewModel: Successfully fetched and updated dashboardData for span \(newDashboardData.span).")
                case .failure(let error):
                    print("HomeViewModel: Failed to fetch dashboard data. Raw error: \(error)")

                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "認証エラーが発生しました。再度お試しいただくか、アプリを再起動してください。"
                        case .apiError(let statusCode, let serverMessage):
                            if statusCode == 500 {
                                self.errorMessage = "サーバーで問題が発生し、ダッシュボード情報を取得できませんでした。しばらくしてからもう一度お試しください。"
                                print("HomeViewModel: Server error 500. Message: \(serverMessage ?? "N/A")")
                            } else {
                                self.errorMessage = "データの取得に失敗しました (コード: \(statusCode))。\(serverMessage ?? "")"
                            }
                        case .decodingError(let decodingError):
                            self.errorMessage = "受信データの解析に失敗しました。アプリのバージョンが最新であるかご確認ください。"
                            print("HomeViewModel: Decoding error - \(decodingError)")
                        default:
                            self.errorMessage = "予期せぬエラーが発生しました。しばらくしてからもう一度お試しください。"
                        }
                    } else {
                        self.errorMessage = "通信エラーが発生しました。ネットワーク接続を確認してください。"
                    }
                }
            }
        }
    }
}
