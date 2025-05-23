//
//  CacheMetadata+CoreData.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import CoreData

@objc(CacheMetadata)
public class CacheMetadata: NSManagedObject {
    
}

extension CacheMetadata {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheMetadata> {
        return NSFetchRequest<CacheMetadata>(entityName: "CacheMetadata")
    }
    
    @NSManaged public var key: String
    @NSManaged public var lastFetchedAt: Date
    @NSManaged public var expiresAt: Date
    @NSManaged public var isValid: Bool
}

extension CacheMetadata {
    /// キャッシュが有効かどうかを判定
    var isCacheValid: Bool {
        return isValid && Date() < expiresAt
    }
    
    /// メタデータを更新
    func updateMetadata(expirationDate: Date) {
        self.lastFetchedAt = Date()
        self.expiresAt = expirationDate
        self.isValid = true
    }
    
    /// キャッシュを無効化
    func invalidate() {
        self.isValid = false
    }
    
    /// 指定されたキーのメタデータを取得または作成
    static func findOrCreate(
        key: String,
        context: NSManagedObjectContext
    ) -> CacheMetadata {
        let request: NSFetchRequest<CacheMetadata> = CacheMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", key)
        request.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(request).first {
                return existing
            }
        } catch {
            print("Error fetching CacheMetadata: \(error)")
        }
        
        // 新規作成
        let metadata = CacheMetadata(context: context)
        metadata.key = key
        metadata.lastFetchedAt = Date()
        metadata.expiresAt = Date()
        metadata.isValid = false
        return metadata
    }
}

// MARK: - Cache Keys
extension CacheMetadata {
    enum CacheKey {
        static let allExercises = "all_exercises"
        static let recentExercises = "recent_exercises"
    }
}
