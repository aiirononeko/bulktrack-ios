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
    @Published var exercises: [ExerciseEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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
        guard session.isReachable else { // isReachableの確認はViewModelの責務として残すか、UseCaseに含めるか検討
            errorMessage = "iPhone と通信できません"
            isLoading = false // エラー時はisLoadingをfalseに
            return
        }
        errorMessage = nil
        isLoading = true
        requestRecentExercisesUseCase.execute(limit: limit)
        // 結果はPublisher経由で受け取るため、isLoadingをfalseにするタイミングはPublisher側
    }

    // MARK: - private
    private func bindSessionCallbacks() {
        session.recentExercisesPublisher
            .receive(on: RunLoop.main)        // 念のためメインスレッドへ
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] list in
                self?.isLoading = false
                self?.exercises = list
            }
            .store(in: &cancellables)
    }
}
