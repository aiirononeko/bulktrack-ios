//
//  ExerciseCacheRepository.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import CoreData
import Domain

public protocol ExerciseCacheRepositoryProtocol {
    /// 全種目をキャッシュから取得
    func getAllExercisesFromCache() throws -> [ExerciseEntity]
    
    /// 全種目をキャッシュに保存
    func saveAllExercisesToCache(_ exercises: [ExerciseEntity]) throws
    
    /// 全種目キャッシュが有効かどうか確認
    func isAllExercisesCacheValid() -> Bool
    
    /// 全種目キャッシュを無効化
    func invalidateAllExercisesCache() throws
    
    /// 全種目キャッシュをクリア
    func clearAllExercisesCache() throws
}

public final class ExerciseCacheRepository: ExerciseCacheRepositoryProtocol {
    private let persistentContainer: PersistentContainer
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 1日
    
    public init(persistentContainer: PersistentContainer = PersistentContainer.shared) {
        self.persistentContainer = persistentContainer
    }
    
    private var context: NSManagedObjectContext {
        return persistentContainer.context
    }
    
    // MARK: - ExerciseCacheRepositoryProtocol
    
    public func getAllExercisesFromCache() throws -> [ExerciseEntity] {
        let request: NSFetchRequest<ExerciseCacheEntity> = ExerciseCacheEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let cacheEntities = try context.fetch(request)
        return cacheEntities.map { $0.toDomainEntity() }
    }
    
    public func saveAllExercisesToCache(_ exercises: [ExerciseEntity]) throws {
        // 既存のキャッシュをクリア
        try clearAllExercisesCache()
        
        // 新しいデータを保存
        for exercise in exercises {
            let _ = ExerciseCacheEntity.fromDomainEntity(exercise, context: context)
        }
        
        // メタデータを更新
        let metadata = CacheMetadata.findOrCreate(
            key: CacheMetadata.CacheKey.allExercises,
            context: context
        )
        let expirationDate = Date().addingTimeInterval(cacheExpirationInterval)
        metadata.updateMetadata(expirationDate: expirationDate)
        
        // 保存
        try context.save()
        
        print("Saved \(exercises.count) exercises to cache")
    }
    
    public func isAllExercisesCacheValid() -> Bool {
        let request: NSFetchRequest<CacheMetadata> = CacheMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", CacheMetadata.CacheKey.allExercises)
        request.fetchLimit = 1
        
        do {
            if let metadata = try context.fetch(request).first {
                return metadata.isCacheValid
            }
        } catch {
            print("Error checking cache validity: \(error)")
        }
        
        return false
    }
    
    public func invalidateAllExercisesCache() throws {
        let request: NSFetchRequest<CacheMetadata> = CacheMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", CacheMetadata.CacheKey.allExercises)
        
        let metadataList = try context.fetch(request)
        for metadata in metadataList {
            metadata.invalidate()
        }
        
        try context.save()
        print("Invalidated all exercises cache")
    }
    
    public func clearAllExercisesCache() throws {
        // キャッシュデータを削除
        let exerciseRequest: NSFetchRequest<NSFetchRequestResult> = ExerciseCacheEntity.fetchRequest()
        let deleteExerciseRequest = NSBatchDeleteRequest(fetchRequest: exerciseRequest)
        try context.execute(deleteExerciseRequest)
        
        // メタデータを削除
        let metadataRequest: NSFetchRequest<NSFetchRequestResult> = CacheMetadata.fetchRequest()
        metadataRequest.predicate = NSPredicate(format: "key == %@", CacheMetadata.CacheKey.allExercises)
        let deleteMetadataRequest = NSBatchDeleteRequest(fetchRequest: metadataRequest)
        try context.execute(deleteMetadataRequest)
        
        try context.save()
        print("Cleared all exercises cache")
    }
}
