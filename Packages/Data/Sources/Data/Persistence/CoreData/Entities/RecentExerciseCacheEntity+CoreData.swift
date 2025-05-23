//
//  RecentExerciseCacheEntity+CoreData.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation
import CoreData
import Domain

@objc(RecentExerciseCacheEntity)
public class RecentExerciseCacheEntity: NSManagedObject {
    
}

extension RecentExerciseCacheEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecentExerciseCacheEntity> {
        return NSFetchRequest<RecentExerciseCacheEntity>(entityName: "RecentExerciseCacheEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var isOfficial: Bool
    @NSManaged public var lastUsedAt: Date?
    @NSManaged public var useCount: Int32
    @NSManaged public var cachedAt: Date
    @NSManaged public var recentOrder: Int32
}

extension RecentExerciseCacheEntity {
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
    func updateFromDomainEntity(_ entity: ExerciseEntity, order: Int) {
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
        self.recentOrder = Int32(order)
    }
    
    /// DomainエンティティからCoreDataエンティティを作成（静的メソッド）
    static func fromDomainEntity(
        _ entity: ExerciseEntity,
        order: Int,
        context: NSManagedObjectContext
    ) -> RecentExerciseCacheEntity {
        let cacheEntity = RecentExerciseCacheEntity(context: context)
        cacheEntity.updateFromDomainEntity(entity, order: order)
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
