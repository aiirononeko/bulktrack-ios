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
    private let session: SessionSyncRepository
    private var cancellables = Set<AnyCancellable>()

    init(session: SessionSyncRepository = DIContainer.shared.sessionSyncRepository) {
        self.session = session
        bindSessionCallbacks()
    }

    /// iPhone へメッセージを送り「最近種目」を取得
    func fetchRecentExercises(limit: Int = 20) {
        guard session.isReachable else {
            errorMessage = "iPhone と通信できません"
            return
        }
        errorMessage = nil
        isLoading = true
        session.requestRecentExercises(limit: limit)
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
