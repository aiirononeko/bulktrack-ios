import Foundation
import Domain
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    private let fetchDashboardUseCase: FetchDashboardUseCase
    private var cancellables = Set<AnyCancellable>()

    @Published var dashboardData: DashboardEntity?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init(fetchDashboardUseCase: FetchDashboardUseCase) {
        self.fetchDashboardUseCase = fetchDashboardUseCase
        print("[HomeViewModel] Initialized with FetchDashboardUseCase.")
    }

    func fetchDashboardData(span: String = "4w") {
        print("[HomeViewModel] fetchDashboardData called with span: \(span)")
        isLoading = true
        errorMessage = nil
        dashboardData = nil

        Task {
            let result = await fetchDashboardUseCase.execute(span: span, locale: "ja")
            isLoading = false
            switch result {
            case .success(let entity):
                dashboardData = entity
                print("[HomeViewModel] Successfully fetched dashboard data: \(entity)")
            case .failure(let error):
                errorMessage = error.localizedDescription
                print("[HomeViewModel] Failed to fetch dashboard data: \(error.localizedDescription)")
            }
        }
    }
}
