//
//  LocalWorkoutSetEntity+CoreData.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/25.
//

import Foundation
import CoreData
import Domain

@objc(LocalWorkoutSetEntity)
public class LocalWorkoutSetEntity: NSManagedObject {
    
}

extension LocalWorkoutSetEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalWorkoutSetEntity> {
        return NSFetchRequest<LocalWorkoutSetEntity>(entityName: "LocalWorkoutSetEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var exerciseId: UUID
    @NSManaged public var exerciseName: String
    @NSManaged public var setNumber: Int32
    @NSManaged public var weight: Double
    @NSManaged public var reps: Int32
    @NSManaged public var rpe: Double
    @NSManaged public var performedAt: Date
    @NSManaged public var workoutDate: Date
    
}

// MARK: - Domain Entity Conversion

extension LocalWorkoutSetEntity {
    
    /// Convert CoreData entity to Domain entity
    func toDomainEntity() -> Domain.LocalWorkoutSetEntity {
        return Domain.LocalWorkoutSetEntity(
            id: self.id,
            exerciseId: self.exerciseId,
            setNumber: Int(self.setNumber),
            weight: self.weight,
            reps: Int(self.reps),
            rpe: self.rpe == 0 ? nil : self.rpe,
            performedAt: self.performedAt
        )
    }
    
    /// Update CoreData entity from Domain entity
    func update(from domainEntity: Domain.LocalWorkoutSetEntity, exerciseName: String, context: NSManagedObjectContext) {
        self.id = domainEntity.id
        self.exerciseId = domainEntity.exerciseId
        self.exerciseName = exerciseName
        self.setNumber = Int32(domainEntity.setNumber)
        self.weight = domainEntity.weight
        self.reps = Int32(domainEntity.reps)
        self.rpe = domainEntity.rpe ?? 0
        self.performedAt = domainEntity.performedAt
        
        // workoutDate は日付のみ（時刻は0:00:00）
        let calendar = Calendar.current
        self.workoutDate = calendar.startOfDay(for: domainEntity.performedAt)
    }
    
    /// Create new CoreData entity from Domain entity
    static func create(from domainEntity: Domain.LocalWorkoutSetEntity, exerciseName: String, context: NSManagedObjectContext) -> LocalWorkoutSetEntity {
        let entity = LocalWorkoutSetEntity(context: context)
        entity.update(from: domainEntity, exerciseName: exerciseName, context: context)
        return entity
    }
}

// MARK: - Identifiable

extension LocalWorkoutSetEntity: Identifiable {
    
}
