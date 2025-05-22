import Foundation

public protocol FetchDashboardUseCase {
    func execute(span: String) async -> Result<DashboardEntity, AppError>
}

public final class DefaultFetchDashboardUseCase: FetchDashboardUseCase {
    private let repository: DashboardRepository

    public init(repository: DashboardRepository) {
        self.repository = repository
    }

    public func execute(span: String) async -> Result<DashboardEntity, AppError> {
        return await repository.fetchDashboard(span: span)
    }
}
