//
//  PayloadMapper.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Domain
import Data // Assuming the Swift Package product for DTOs is named "Data"

enum PayloadMapper {

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        // Adjust formatOptions based on how dates are expected/stored.
        // .withInternetDateTime includes date, time, and Z or timezone offset.
        // If only date is needed, or a specific format, adjust accordingly.
        // For `lastUsedAt: { type: [string, "null"], format: date-time }`
        // .withInternetDateTime is a good default.
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func mapToExerciseEntities(from dtos: [ExerciseDTO]) -> [ExerciseEntity] {
        return dtos.map { mapToExerciseEntity(from: $0) }
    }

    static func mapToExerciseEntity(from dto: ExerciseDTO) -> ExerciseEntity {
        let isoLastUsedAtString: ISODate? // ISODate is String
        if let date = dto.lastUsedAt {
            isoLastUsedAtString = self.iso8601Formatter.string(from: date)
        } else {
            isoLastUsedAtString = nil
        }

        return ExerciseEntity(
            id: dto.id,
            name: dto.name,
            isOfficial: dto.isOfficial, // Bool can be assigned to Bool?
            lastUsedAt: isoLastUsedAtString,
            useCount: dto.useCount
        )
    }
}
