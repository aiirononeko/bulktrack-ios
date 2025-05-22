//
//  RecentExercisesViewModel.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import SwiftUI
import Domain
import Combine

@MainActor
final class RecentExercisesViewModel: ObservableObject {
    // MARK: - Output
    @Published var recentExercisesState: ResultState<[ExerciseEntity], AppError> = .idle

    // MARK: - Dependencies
    private let requestRecentExercisesUseCase: RequestRecentExercisesUseCaseProtocol
    private let session: SessionSyncRepository // Publisher購読のために保持
    private var cancellables = Set<AnyCancellable>()

    init(
        requestRecentExercisesUseCase: RequestRecentExercisesUseCaseProtocol = DIContainer.shared.requestRecentExercisesUseCase,
        session: SessionSyncRepository = DIContainer.shared.sessionSyncRepository
    ) {
        self.requestRecentExercisesUseCase = requestRecentExercisesUseCase
        self.session = session
        bindSessionCallbacks()
    }

    /// iPhone へメッセージを送り「最近種目」を取得
    func fetchRecentExercises(limit: Int = 20) {
        guard session.isReachable else {
            recentExercisesState = .failure(.networkError(.noConnection)) // Or a more specific WCSession error
            return
        }
        recentExercisesState = .loading
        requestRecentExercisesUseCase.execute(limit: limit)
        // 結果はPublisher経由で受け取る
    }

    // MARK: - private
    private func bindSessionCallbacks() {
        session.recentExercisesPublisher
            .receive(on: RunLoop.main)        // 念のためメインスレッドへ
            .sink { [weak self] completion in
                if case let .failure(err) = completion {
                    // Map WCSession error to AppError
                    // This mapping might need to be more specific based on actual errors from WCSessionRelay
                    self?.recentExercisesState = .failure(.networkError(.underlying(err.localizedDescription)))
                }
                // isLoading is handled by setting state to .success or .failure
            } receiveValue: { [weak self] list in
                self?.recentExercisesState = .success(list)
            }
            .store(in: &cancellables)
    }
}
