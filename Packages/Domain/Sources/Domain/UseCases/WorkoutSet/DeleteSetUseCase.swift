//
//  DeleteSetUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public protocol DeleteSetUseCaseProtocol {
    func execute(setId: UUID) async -> Result<Void, AppError>
}

public struct DeleteSetUseCase: DeleteSetUseCaseProtocol {
    private let setRepository: SetRepository
    
    public init(setRepository: SetRepository) {
        self.setRepository = setRepository
    }
    
    public func execute(setId: UUID) async -> Result<Void, AppError> {
        do {
            try await setRepository.deleteSet(setId: setId)
            return .success(())
        } catch {
            return .failure(.unknownError("セットの削除に失敗しました: \(error.localizedDescription)"))
        }
    }
}
