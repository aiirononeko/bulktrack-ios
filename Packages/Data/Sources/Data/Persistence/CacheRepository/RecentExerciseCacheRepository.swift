//
//  RecentExerciseCacheRepository.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import CoreData
import Domain

public protocol RecentExerciseCacheRepositoryProtocol {
    /// 最近の種目をキャッシュから取得
    func getRecentExercisesFromCache(limit: Int, offset: Int) throws -> [ExerciseEntity]
    
    /// 最近の種目をキャッシュに保存
    func saveRecentExercisesToCache(_ exercises: [ExerciseEntity]) throws
    
    /// 最近の種目キャッシュが有効かどうか確認
    func isRecentExercisesCacheValid() -> Bool
    
    /// 最近の種目キャッシュを無効化
    func invalidateRecentExercisesCache() throws
    
    /// 最近の種目キャッシュをクリア
    func clearRecentExercisesCache() throws
}

public final class RecentExerciseCacheRepository: RecentExerciseCacheRepositoryProtocol {
    private let persistentContainer: PersistentContainer
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 1日
    
    public init(persistentContainer: PersistentContainer = PersistentContainer.shared) {
        self.persistentContainer = persistentContainer
    }
    
    private var context: NSManagedObjectContext {
        return persistentContainer.context
    }
    
    // MARK: - RecentExerciseCacheRepositoryProtocol
    
    public func getRecentExercisesFromCache(limit: Int, offset: Int) throws -> [ExerciseEntity] {
        let request: NSFetchRequest<RecentExerciseCacheEntity> = RecentExerciseCacheEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "recentOrder", ascending: true)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let cacheEntities = try context.fetch(request)
        return cacheEntities.map { $0.toDomainEntity() }
    }
    
    public func saveRecentExercisesToCache(_ exercises: [ExerciseEntity]) throws {
        // 既存のキャッシュをクリア
        try clearRecentExercisesCache()
        
        // 新しいデータを保存（順序を保持）
        for (index, exercise) in exercises.enumerated() {
            let _ = RecentExerciseCacheEntity.fromDomainEntity(
                exercise,
                order: index,
                context: context
            )
        }
        
        // メタデータを更新
        let metadata = CacheMetadata.findOrCreate(
            key: CacheMetadata.CacheKey.recentExercises,
            context: context
        )
        let expirationDate = Date().addingTimeInterval(cacheExpirationInterval)
        metadata.updateMetadata(expirationDate: expirationDate)
        
        // 保存
        try context.save()
        
        print("Saved \(exercises.count) recent exercises to cache")
    }
    
    public func isRecentExercisesCacheValid() -> Bool {
        let request: NSFetchRequest<CacheMetadata> = CacheMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", CacheMetadata.CacheKey.recentExercises)
        request.fetchLimit = 1
        
        do {
            if let metadata = try context.fetch(request).first {
                return metadata.isCacheValid
            }
        } catch {
            print("Error checking recent exercises cache validity: \(error)")
        }
        
        return false
    }
    
    public func invalidateRecentExercisesCache() throws {
        let request: NSFetchRequest<CacheMetadata> = CacheMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", CacheMetadata.CacheKey.recentExercises)
        
        let metadataList = try context.fetch(request)
        for metadata in metadataList {
            metadata.invalidate()
        }
        
        try context.save()
        print("Invalidated recent exercises cache")
    }
    
    public func clearRecentExercisesCache() throws {
        // キャッシュデータを削除
        let exerciseRequest: NSFetchRequest<NSFetchRequestResult> = RecentExerciseCacheEntity.fetchRequest()
        let deleteExerciseRequest = NSBatchDeleteRequest(fetchRequest: exerciseRequest)
        try context.execute(deleteExerciseRequest)
        
        // メタデータを削除
        let metadataRequest: NSFetchRequest<NSFetchRequestResult> = CacheMetadata.fetchRequest()
        metadataRequest.predicate = NSPredicate(format: "key == %@", CacheMetadata.CacheKey.recentExercises)
        let deleteMetadataRequest = NSBatchDeleteRequest(fetchRequest: metadataRequest)
        try context.execute(deleteMetadataRequest)
        
        try context.save()
        print("Cleared recent exercises cache")
    }
}
