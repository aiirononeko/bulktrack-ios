//
//  WorkoutHistoryRepository.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/25.
//

import Foundation
import CoreData
import Domain

public final class CoreDataWorkoutHistoryRepository: Domain.WorkoutHistoryRepository {
    private let persistentContainer: PersistentContainer
    
    public init(persistentContainer: PersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    public func saveWorkoutSet(_ set: Domain.LocalWorkoutSetEntity) async throws {
        let context = persistentContainer.context
        
        // Exercise名を取得（キャッシュから）
        let exerciseName = getExerciseName(for: set.exerciseId, context: context) ?? "Unknown Exercise"
        
        // 古いデータのクリーンアップ（3日より古い）
        cleanupOldData(context: context)
        
        // 新しいセットを保存
        _ = LocalWorkoutSetEntity.create(from: set, exerciseName: exerciseName, context: context)
        
        try context.save()
    }
    
    public func getPreviousWorkout(exerciseId: UUID) async throws -> Domain.WorkoutHistoryEntity? {
        let context = persistentContainer.context
        
        let request: NSFetchRequest<LocalWorkoutSetEntity> = LocalWorkoutSetEntity.fetchRequest()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 今日より前の日付でグループ化
        request.predicate = NSPredicate(
            format: "exerciseId == %@ AND workoutDate < %@",
            exerciseId as CVarArg,
            today as CVarArg
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalWorkoutSetEntity.workoutDate, ascending: false),
            NSSortDescriptor(keyPath: \LocalWorkoutSetEntity.setNumber, ascending: true)
        ]
        
        let entities = try context.fetch(request)
        
        guard let firstEntity = entities.first else {
            return nil
        }
        
        // 最新日付のセットのみを取得
        let latestDate = firstEntity.workoutDate
        let latestSets = entities.filter { calendar.isDate($0.workoutDate, inSameDayAs: latestDate) }
        
        // WorkoutSetEntityに変換
        let workoutSets = latestSets.map { entity in
            Domain.WorkoutSetEntity(
                id: entity.id,
                exerciseId: entity.exerciseId,
                setNumber: Int(entity.setNumber),
                weight: entity.weight,
                reps: Int(entity.reps),
                rpe: entity.rpe == 0 ? nil : entity.rpe,
                notes: nil,
                performedAt: entity.performedAt
            )
        }
        
        return Domain.WorkoutHistoryEntity(
            id: UUID(),
            exerciseId: exerciseId,
            exerciseName: firstEntity.exerciseName,
            performedAt: latestDate,
            sets: workoutSets
        )
    }
    
    public func getTodaysSets(exerciseId: UUID) async throws -> [Domain.LocalWorkoutSetEntity] {
        let context = persistentContainer.context
        
        let request: NSFetchRequest<LocalWorkoutSetEntity> = LocalWorkoutSetEntity.fetchRequest()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(
            format: "exerciseId == %@ AND workoutDate >= %@ AND workoutDate < %@",
            exerciseId as CVarArg,
            today as CVarArg,
            tomorrow as CVarArg
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalWorkoutSetEntity.setNumber, ascending: true)
        ]
        
        let entities = try context.fetch(request)
        return entities.map { $0.toDomainEntity() }
    }
    
    public func deleteWorkoutSet(_ setId: UUID) async throws {
        let context = persistentContainer.context
        
        let request: NSFetchRequest<LocalWorkoutSetEntity> = LocalWorkoutSetEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", setId as CVarArg)
        
        let entities = try context.fetch(request)
        
        guard let entity = entities.first else {
            // セットが見つからない場合は正常終了（既に削除済みの可能性）
            return
        }
        
        let exerciseId = entity.exerciseId
        let deletedSetNumber = entity.setNumber
        
        // エンティティを削除
        context.delete(entity)
        
        // 削除されたセットより後のセット番号を更新
        let updateRequest: NSFetchRequest<LocalWorkoutSetEntity> = LocalWorkoutSetEntity.fetchRequest()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        updateRequest.predicate = NSPredicate(
            format: "exerciseId == %@ AND workoutDate >= %@ AND workoutDate < %@ AND setNumber > %d",
            exerciseId as CVarArg,
            today as CVarArg,
            tomorrow as CVarArg,
            deletedSetNumber
        )
        updateRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalWorkoutSetEntity.setNumber, ascending: true)
        ]
        
        let remainingSets = try context.fetch(updateRequest)
        
        // セット番号を1つずつ減らす
        for set in remainingSets {
            set.setNumber = set.setNumber - 1
        }
        
        try context.save()
    }
    
    // MARK: - Private Methods
    
    private func getExerciseName(for exerciseId: UUID, context: NSManagedObjectContext) -> String? {
        let request: NSFetchRequest<ExerciseCacheEntity> = ExerciseCacheEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", exerciseId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            return entities.first?.name
        } catch {
            print("[WorkoutHistoryRepository] Failed to fetch exercise name: \(error)")
            return nil
        }
    }
    
    private func cleanupOldData(context: NSManagedObjectContext) {
        let request: NSFetchRequest<NSFetchRequestResult> = LocalWorkoutSetEntity.fetchRequest()
        
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let cleanupDate = calendar.startOfDay(for: threeDaysAgo)
        
        request.predicate = NSPredicate(format: "workoutDate < %@", cleanupDate as CVarArg)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeStatusOnly
        
        do {
            try context.execute(deleteRequest)
        } catch {
            print("[WorkoutHistoryRepository] Failed to cleanup old data: \(error)")
        }
    }
}
