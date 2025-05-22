//
//  RequestRecentExercisesUseCase.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public protocol RequestRecentExercisesUseCaseProtocol {
    func execute(limit: Int)
}

public final class RequestRecentExercisesUseCase: RequestRecentExercisesUseCaseProtocol {
    private let sessionSyncRepository: SessionSyncRepository

    public init(sessionSyncRepository: SessionSyncRepository) {
        self.sessionSyncRepository = sessionSyncRepository
    }

    public func execute(limit: Int) {
        // 単純にリポジトリのメソッドを呼び出すだけ
        sessionSyncRepository.requestRecentExercises(limit: limit)
    }
}
