//
//  APIServiceProtocol.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Domain

public protocol APIServiceProtocol: ExerciseRepository {
    func bootstrap() async throws
}
