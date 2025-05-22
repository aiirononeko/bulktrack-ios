import Foundation
import Domain

public enum ExerciseMapper {

    private static func createISO8601Formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    public static func toEntity(dto: ExerciseDTO) -> ExerciseEntity {
        let isoLastUsedAt: ISODate? // ISODate is String
        if let date = dto.lastUsedAt {
            let formatter = createISO8601Formatter()
            isoLastUsedAt = formatter.string(from: date)
        } else {
            isoLastUsedAt = nil
        }

        return ExerciseEntity(
            id: dto.id,
            name: dto.name,
            isOfficial: dto.isOfficial, // Bool can be assigned to Bool?
            lastUsedAt: isoLastUsedAt,
            useCount: dto.useCount
        )
    }

    public static func toEntities(dtos: [ExerciseDTO]) -> [ExerciseEntity] {
        dtos.map { toEntity(dto: $0) }
    }

    // Optional: If mapping from Entity back to DTO is needed within Data layer
    // (e.g., if APIService needed to return DTOs for some reason but worked with Entities internally)
    // This is similar to what was added in iOS WCSessionRelay
    public static func toDTO(entity: ExerciseEntity) -> ExerciseDTO {
        let lastUsedAtDate: Date?
        if let isoDateString = entity.lastUsedAt {
            let decoder = createISO8601Formatter() // Can use the same formatter for decoding
            lastUsedAtDate = decoder.date(from: isoDateString)
        } else {
            lastUsedAtDate = nil
        }

        return ExerciseDTO(
            id: entity.id,
            name: entity.name,
            isOfficial: entity.isOfficial,
            lastUsedAt: lastUsedAtDate,
            useCount: entity.useCount
        )
    }
    
    public static func toDTOs(entities: [ExerciseEntity]) -> [ExerciseDTO] {
        entities.map { toDTO(entity: $0) }
    }
}
