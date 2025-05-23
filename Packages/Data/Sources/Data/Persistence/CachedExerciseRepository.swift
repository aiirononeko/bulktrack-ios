//
//  CachedExerciseRepository.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import Domain

public final class CachedExerciseRepository: CacheableExerciseRepository {
    private let apiService: APIService
    private let exerciseCacheRepository: ExerciseCacheRepositoryProtocol
    private let recentExerciseCacheRepository: RecentExerciseCacheRepositoryProtocol
    public let cacheInvalidationService: CacheInvalidationServiceProtocol
    
    public init(
        apiService: APIService,
        exerciseCacheRepository: ExerciseCacheRepositoryProtocol,
        recentExerciseCacheRepository: RecentExerciseCacheRepositoryProtocol,
        cacheInvalidationService: CacheInvalidationServiceProtocol
    ) {
        self.apiService = apiService
        self.exerciseCacheRepository = exerciseCacheRepository
        self.recentExerciseCacheRepository = recentExerciseCacheRepository
        self.cacheInvalidationService = cacheInvalidationService
    }
    
    // MARK: - ExerciseRepository
    
    public func searchExercises(query: String?, locale: String?) async throws -> [ExerciseEntity] {
        // 検索クエリが指定されている場合はキャッシュをスルーして直接APIから取得
        if let searchQuery = query, !searchQuery.isEmpty {
            print("Search query detected, bypassing cache and fetching from API")
            return try await apiService.searchExercises(query: query, locale: locale)
        }
        
        // クエリが空またはnilの場合（全件取得）のみキャッシュを使用
        // 1. キャッシュの有効性をチェック
        if exerciseCacheRepository.isAllExercisesCacheValid() {
            print("Using cached exercises for all exercises")
            
            do {
                let cachedExercises = try exerciseCacheRepository.getAllExercisesFromCache()
                return cachedExercises
            } catch {
                print("Failed to retrieve cached exercises, falling back to API: \(error)")
                // キャッシュ取得に失敗した場合はAPIにフォールバック
            }
        }
        
        // 2. キャッシュが無効またはエラーの場合はAPIから取得
        print("Fetching all exercises from API")
        do {
            let apiExercises = try await apiService.searchExercises(query: query, locale: locale)
            
            // 3. 全件取得の場合のみキャッシュに保存
            do {
                try exerciseCacheRepository.saveAllExercisesToCache(apiExercises)
            } catch {
                print("Failed to save exercises to cache: \(error)")
                // キャッシュ保存失敗してもAPIの結果は返す
            }
            
            return apiExercises
        } catch {
            // APIも失敗した場合、キャッシュが利用可能であれば最後の手段として返す
            if let cachedExercises = try? exerciseCacheRepository.getAllExercisesFromCache(),
               !cachedExercises.isEmpty {
                print("API failed, using stale cache as fallback")
                return cachedExercises
            }
            
            throw error
        }
    }
    
    public func recentExercises(limit: Int, offset: Int, locale: String?) async throws -> [ExerciseEntity] {
        // 1. キャッシュの有効性をチェック
        if recentExerciseCacheRepository.isRecentExercisesCacheValid() {
            print("Using cached recent exercises")
            
            do {
                let cachedRecentExercises = try recentExerciseCacheRepository.getRecentExercisesFromCache(
                    limit: limit,
                    offset: offset
                )
                return cachedRecentExercises
            } catch {
                print("Failed to retrieve cached recent exercises, falling back to API: \(error)")
                // キャッシュ取得に失敗した場合はAPIにフォールバック
            }
        }
        
        // 2. キャッシュが無効またはエラーの場合はAPIから取得
        print("Fetching recent exercises from API")
        do {
            let apiRecentExercises = try await apiService.recentExercises(
                limit: limit,
                offset: offset,
                locale: locale
            )
            
            // 3. offset == 0 の場合（最初のページ）のみキャッシュに保存
            if offset == 0 {
                do {
                    try recentExerciseCacheRepository.saveRecentExercisesToCache(apiRecentExercises)
                } catch {
                    print("Failed to save recent exercises to cache: \(error)")
                    // キャッシュ保存失敗してもAPIの結果は返す
                }
            }
            
            return apiRecentExercises
        } catch {
            // APIも失敗した場合、キャッシュが利用可能であれば最後の手段として返す
            if let cachedRecentExercises = try? recentExerciseCacheRepository.getRecentExercisesFromCache(
                limit: limit,
                offset: offset
            ), !cachedRecentExercises.isEmpty {
                print("API failed, using stale recent exercises cache as fallback")
                return cachedRecentExercises
            }
            
            throw error
        }
    }
}
