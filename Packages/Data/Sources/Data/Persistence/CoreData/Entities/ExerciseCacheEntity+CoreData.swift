//
//  ExerciseCacheEntity+CoreData.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import CoreData
import Domain

@objc(ExerciseCacheEntity)
public class ExerciseCacheEntity: NSManagedObject {
    
}

extension ExerciseCacheEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseCacheEntity> {
        return NSFetchRequest<ExerciseCacheEntity>(entityName: "ExerciseCacheEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var isOfficial: Bool
    @NSManaged public var lastUsedAt: Date?
    @NSManaged public var useCount: Int32
    @NSManaged public var cachedAt: Date
}

extension ExerciseCacheEntity {
    /// CoreDataエンティティからDomainエンティティに変換
    func toDomainEntity() -> ExerciseEntity {
        return ExerciseEntity(
            id: id,
            name: name,
            isOfficial: isOfficial,
            lastUsedAt: lastUsedAt?.toISODate(),
            useCount: useCount > 0 ? Int(useCount) : nil
        )
    }
    
    /// DomainエンティティからCoreDataエンティティを更新
    func updateFromDomainEntity(_ entity: ExerciseEntity) {
        self.id = entity.id
        self.name = entity.name
        self.isOfficial = entity.isOfficial ?? false
        if let lastUsedAtString = entity.lastUsedAt {
            self.lastUsedAt = lastUsedAtString.toDate()
        } else {
            self.lastUsedAt = nil
        }
        self.useCount = Int32(entity.useCount ?? 0)
        self.cachedAt = Date()
    }
    
    /// DomainエンティティからCoreDataエンティティを作成（静的メソッド）
    static func fromDomainEntity(
        _ entity: ExerciseEntity,
        context: NSManagedObjectContext
    ) -> ExerciseCacheEntity {
        let cacheEntity = ExerciseCacheEntity(context: context)
        cacheEntity.updateFromDomainEntity(entity)
        return cacheEntity
    }
}

// MARK: - Helper Extensions for Date conversion
private extension Date {
    func toISODate() -> ISODate {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

private extension ISODate {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}
