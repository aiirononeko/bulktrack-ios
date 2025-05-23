//
//  CacheInvalidationService.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import Domain

public final class CacheInvalidationService: CacheInvalidationServiceProtocol {
    private let exerciseCacheRepository: ExerciseCacheRepositoryProtocol
    private let recentExerciseCacheRepository: RecentExerciseCacheRepositoryProtocol
    
    public init(
        exerciseCacheRepository: ExerciseCacheRepositoryProtocol,
        recentExerciseCacheRepository: RecentExerciseCacheRepositoryProtocol
    ) {
        self.exerciseCacheRepository = exerciseCacheRepository
        self.recentExerciseCacheRepository = recentExerciseCacheRepository
    }
    
    // MARK: - CacheInvalidationServiceProtocol
    
    public func invalidateAllExercises() async {
        do {
            try exerciseCacheRepository.invalidateAllExercisesCache()
            print("Successfully invalidated all exercises cache")
        } catch {
            print("Failed to invalidate all exercises cache: \(error)")
        }
    }
    
    public func invalidateRecentExercises() async {
        do {
            try recentExerciseCacheRepository.invalidateRecentExercisesCache()
            print("Successfully invalidated recent exercises cache")
        } catch {
            print("Failed to invalidate recent exercises cache: \(error)")
        }
    }
    
    public func invalidateAllCaches() async {
        await invalidateAllExercises()
        await invalidateRecentExercises()
        print("Successfully invalidated all caches")
    }
}
