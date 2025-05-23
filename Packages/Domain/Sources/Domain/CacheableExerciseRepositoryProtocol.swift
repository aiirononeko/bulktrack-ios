//
//  CacheableExerciseRepositoryProtocol.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation

public protocol CacheableExerciseRepository: ExerciseRepository {
    var cacheInvalidationService: CacheInvalidationServiceProtocol { get }
}
