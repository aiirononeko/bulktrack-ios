//
//  WorkoutSetMapper.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation
import Domain

public struct WorkoutSetMapper {
    /// Maps a WorkoutSetDTO to a WorkoutSetEntity
    public static func toEntity(_ dto: WorkoutSetDTO) -> WorkoutSetEntity {
        return WorkoutSetEntity(
            id: dto.id,
            exerciseId: dto.exerciseId,
            setNumber: dto.setNumber,
            weight: dto.weight,
            reps: dto.reps,
            rpe: dto.rpe,
            notes: dto.notes,
            performedAt: dto.performedAt
        )
    }
    
    /// Maps an array of WorkoutSetDTOs to an array of WorkoutSetEntities
    public static func toEntities(_ dtos: [WorkoutSetDTO]) -> [WorkoutSetEntity] {
        return dtos.map(toEntity)
    }
    
    /// Maps a CreateSetRequest to a SetCreateDTO
    public static func toSetCreateDTO(_ request: CreateSetRequest) -> SetCreateDTO {
        return SetCreateDTO(
            exerciseId: request.exerciseId,
            weight: request.weight,
            reps: request.reps,
            rpe: request.rpe,
            notes: request.notes,
            performedAt: request.performedAt
        )
    }
    
    /// Maps an UpdateSetRequest to a SetUpdateDTO
    public static func toSetUpdateDTO(_ request: UpdateSetRequest) -> SetUpdateDTO {
        return SetUpdateDTO(
            exerciseId: request.exerciseId,
            weight: request.weight,
            reps: request.reps,
            rpe: request.rpe,
            notes: request.notes,
            performedAt: request.performedAt
        )
    }
}
