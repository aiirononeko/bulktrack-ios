import Foundation
import Combine // ObservableObjectと@Publishedのために必要

// APIServiceから取得するDashboardResponse.CurrentWeekSummaryをViewに渡すためのViewModel
class HomeViewModel: ObservableObject {
    @Published var dashboardData: DashboardResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var bodyPartVolumes: [BodyPartVolumeViewModel] = [] // 部位別ボリュームデータ

    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>() // Combineの購読管理用

    // 部位カテゴリとmuscleIdのマッピングルール
    private let muscleIdMapping: [String: [Int]] = [
        "胸": [1, 9],
        "肩": [2, 10],
        "腕": [3, 4, 5],
        "背中": [6, 7, 8, 13],
        "脚": [15, 16, 17, 18, 19, 20, 21, 22],
        "腹筋": [11, 12, 14]
    ]
    // 表示順を定義
    private let bodyPartOrder: [String] = ["胸", "背中", "肩", "腕", "脚", "腹筋"]

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
                    self.updateBodyPartVolumes() // ダッシュボードデータ成功時に部位別ボリュームも更新
                case .failure(let error):
                    print("HomeViewModel: Failed to fetch dashboard data. Raw error: \(error)")
                    self.bodyPartVolumes = [] // エラー時はクリア

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

    // 部位別ボリュームデータを生成・更新するメソッド
    private func updateBodyPartVolumes() {
        guard let dashboardData = dashboardData,
              !dashboardData.muscles.isEmpty else {
            self.bodyPartVolumes = []
            return
        }

        let thisWeekStartDate = dashboardData.thisWeek.weekStart

        var aggregatedVolumes: [String: Double] = [:]
        for (category, _) in muscleIdMapping {
            aggregatedVolumes[category] = 0.0 // 各カテゴリのボリュームを0で初期化
        }

        for muscleData in dashboardData.muscles {
            // 今週のデータポイントを探す
            if let currentWeekPoint = muscleData.points.first(where: { $0.weekStart == thisWeekStartDate }) {
                let volume = currentWeekPoint.totalVolume
                
                // このmuscleIdがどのUIカテゴリに属するかを見つける
                for (category, idsIncategory) in muscleIdMapping {
                    if idsIncategory.contains(muscleData.muscleId) {
                        aggregatedVolumes[category, default: 0.0] += volume
                        break // 1つのmuscleIdは1つのカテゴリにのみ属すると仮定
                    }
                }
            }
        }
        
        // bodyPartOrderに基づいてソートし、ボリュームが0より大きいもののみをリスト化
        self.bodyPartVolumes = bodyPartOrder.compactMap { categoryName in
            if let volume = aggregatedVolumes[categoryName] {
                return BodyPartVolumeViewModel(name: categoryName, volume: volume)
            }
            return nil
        }
        
        // もし特定の順序が不要なら、以下のように直接変換も可能
        // self.bodyPartVolumes = aggregatedVolumes.filter { $0.value > 0 }.map { categoryName, volume in
        //     BodyPartVolumeViewModel(name: categoryName, volume: volume)
        // }
        // ただし、この場合表示順が不定になる可能性があるため、bodyPartOrderを使用。
    }
}

// Viewで使うための部位別ボリュームのデータ構造
struct BodyPartVolumeViewModel: Identifiable {
    let id = UUID()
    let name: String
    let volume: Double
}
