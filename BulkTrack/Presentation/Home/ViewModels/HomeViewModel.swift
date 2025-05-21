//import Foundation
//import Combine // ObservableObjectと@Publishedのために必要
//
//// APIServiceから取得するDashboardResponse.CurrentWeekSummaryをViewに渡すためのViewModel
//class HomeViewModel: ObservableObject {
//    @Published var dashboardData: DashboardResponse? = nil
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String? = nil
//    @Published var bodyPartVolumes: [BodyPartVolumeViewModel] = [] // 部位別ボリュームデータ
//
//    private let apiService = APIService()
//    private var cancellables = Set<AnyCancellable>() // Combineの購読管理用
//
//    // 英語のgroupNameから日本語のUI表示名へのマッピング
//    private let groupNameJpMapping: [String: String] = [
//        "Chest": "胸",
//        "Back": "背中",
//        "Shoulders": "肩",
//        "Arms": "腕",
//        "Legs": "脚",
//        "Core": "腹筋",
//        "Hip & Glutes": "脚" // Hip & Glutes も「脚」カテゴリに集約
//    ]
//    
//    // 表示順を定義
//    private let bodyPartOrder: [String] = ["胸", "背中", "肩", "腕", "脚", "腹筋"]
//
//    init() {
//        // fetchDashboardData() // init時に自動で取得開始するか、ViewのonAppearで呼ぶかを選択
//    }
//
//    func fetchDashboardData(period: String = "4w") { // APIのデフォルトは "1w" だが、ViewModelでは "4w" を維持
//        isLoading = true
//        errorMessage = nil
//        dashboardData = nil // 以前のデータをクリア
//
//        apiService.fetchDashboard(period: period) { [weak self] result in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async { // UI更新はメインスレッドで
//                self.isLoading = false
//                switch result {
//                case .success(let newDashboardData):
//                    self.dashboardData = newDashboardData // 新しいDashboardResponse全体を格納
//                    print("HomeViewModel: Successfully fetched and updated dashboardData for span \(newDashboardData.span).")
//                    self.updateBodyPartVolumes() // ダッシュボードデータ成功時に部位別ボリュームも更新
//                case .failure(let error):
//                    print("HomeViewModel: Failed to fetch dashboard data. Raw error: \(error)")
//                    self.bodyPartVolumes = [] // エラー時はクリア
//
//                    if let apiError = error as? APIError {
//                        switch apiError {
//                        case .unauthorized:
//                            self.errorMessage = "認証エラーが発生しました。再度お試しいただくか、アプリを再起動してください。"
//                        case .apiError(let statusCode, let serverMessage):
//                            if statusCode == 500 {
//                                self.errorMessage = "サーバーで問題が発生し、ダッシュボード情報を取得できませんでした。しばらくしてからもう一度お試しください。"
//                                print("HomeViewModel: Server error 500. Message: \(serverMessage ?? "N/A")")
//                            } else {
//                                self.errorMessage = "データの取得に失敗しました (コード: \(statusCode))。\(serverMessage ?? "")"
//                            }
//                        case .decodingError(let decodingError):
//                            self.errorMessage = "受信データの解析に失敗しました。アプリのバージョンが最新であるかご確認ください。"
//                            print("HomeViewModel: Decoding error - \(decodingError)")
//                        default:
//                            self.errorMessage = "予期せぬエラーが発生しました。しばらくしてからもう一度お試しください。"
//                        }
//                    } else {
//                        self.errorMessage = "通信エラーが発生しました。ネットワーク接続を確認してください。"
//                    }
//                }
//            }
//        }
//    }
//
//    // 部位別ボリュームデータを生成・更新するメソッド
//    private func updateBodyPartVolumes() {
//        guard let dashboardData = dashboardData,
//              !dashboardData.muscleGroups.isEmpty else { // muscles から muscleGroups に変更
//            self.bodyPartVolumes = []
//            return
//        }
//
//        let thisWeekStartDate = dashboardData.thisWeek.weekStart
//
//        // bodyPartOrder に基づいて集計用辞書を初期化
//        var aggregatedVolumes: [String: Double] = bodyPartOrder.reduce(into: [:]) { $0[$1] = 0.0 }
//
//        for groupData in dashboardData.muscleGroups { // muscleData から groupData に変更、型も MuscleGroupSeries
//            // 今週のデータポイントを探す (points の型は MuscleGroupPointDetail)
//            if let currentWeekPoint = groupData.points.first(where: { $0.weekStart == thisWeekStartDate }) {
//                let volume = currentWeekPoint.totalVolume
//                
//                // APIからのgroupName (英語) を日本語のUIカテゴリ名にマッピング
//                if let uiCategoryName = groupNameJpMapping[groupData.groupName] {
//                    // bodyPartOrder に含まれるカテゴリ（つまりUIに表示するカテゴリ）のみ集計
//                    if aggregatedVolumes[uiCategoryName] != nil {
//                        aggregatedVolumes[uiCategoryName, default: 0.0] += volume
//                    }
//                } else {
//                    // マッピング定義にない groupName はログに出力しても良い (デバッグ用)
//                    print("HomeViewModel: Unmapped groupName found: \(groupData.groupName)")
//                }
//            }
//        }
//        
//        // bodyPartOrderに基づいてソートし、ボリュームが0より大きいもののみをリスト化
//        // (ボリューム0でも表示したい場合は .filter { $0.value > 0 } を削除または変更)
//        self.bodyPartVolumes = bodyPartOrder.compactMap { categoryName in
//            if let volume = aggregatedVolumes[categoryName] {
//                return BodyPartVolumeViewModel(name: categoryName, volume: volume)
//            }
//            return nil
//        }
//    }
//}
//
//// Viewで使うための部位別ボリュームのデータ構造
//struct BodyPartVolumeViewModel: Identifiable {
//    let id = UUID()
//    let name: String
//    let volume: Double
//}
