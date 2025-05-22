import Foundation
import Domain // DomainレイヤーのEntityをimport

public enum DashboardMapper {

    private static let dateFormatter: DateFormatter = { // Changed var to let
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // APIがUTC日付を返すことを想定
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - DTO to Entity

    public static func toEntity(dto: DashboardResponse) throws -> DashboardEntity { // Changed DashboardResponseDTO to DashboardResponse
        let thisWeekEntity = try toEntity(dto: dto.thisWeek)
        let lastWeekEntity = try toEntity(dto: dto.lastWeek)
        let trendEntities = try dto.trend.map { try toEntity(dto: $0) }
        let muscleGroupEntities = try dto.muscleGroups.map { try toEntity(dto: $0) }
        let metricEntities = try dto.metrics.map { try toEntity(dto: $0) }

        return DashboardEntity(
            thisWeek: thisWeekEntity,
            lastWeek: lastWeekEntity,
            trend: trendEntities,
            muscleGroups: muscleGroupEntities,
            metrics: metricEntities
        )
    }

    public static func toEntity(dto: WeekPointDTO) throws -> WeekPointEntity {
        guard let date = dateFormatter.date(from: dto.weekStart) else {
            throw MappingError.invalidDateString(dto.weekStart)
        }
        return WeekPointEntity(
            weekStart: date,
            totalVolume: dto.totalVolume,
            avgSetVolume: dto.avgSetVolume,
            e1rmAvg: dto.e1rmAvg
        )
    }

    public static func toEntity(dto: MuscleGroupSeriesDTO) throws -> MuscleGroupSeriesEntity {
        let pointEntities = try dto.points.map { try toEntity(dto: $0) }
        return MuscleGroupSeriesEntity(
            muscleGroupId: dto.muscleGroupId,
            groupName: dto.groupName,
            points: pointEntities
        )
    }

    public static func toEntity(dto: MuscleGroupWeekPointDTO) throws -> MuscleGroupWeekPointEntity {
        guard let date = dateFormatter.date(from: dto.weekStart) else {
            throw MappingError.invalidDateString(dto.weekStart)
        }
        return MuscleGroupWeekPointEntity(
            weekStart: date,
            totalVolume: dto.totalVolume,
            setCount: dto.setCount,
            avgE1rm: dto.avgE1rm
        )
    }

    public static func toEntity(dto: MetricSeriesDTO) throws -> MetricSeriesEntity {
        let pointEntities = try dto.points.map { try toEntity(dto: $0) }
        return MetricSeriesEntity(
            metricKey: dto.metricKey,
            unit: dto.unit,
            points: pointEntities
        )
    }

    public static func toEntity(dto: MetricPointDTO) throws -> MetricPointEntity {
        guard let date = dateFormatter.date(from: dto.weekStart) else {
            throw MappingError.invalidDateString(dto.weekStart)
        }
        return MetricPointEntity(
            weekStart: date,
            value: dto.value
        )
    }

    // MARK: - Entity to DTO (Optional, if needed for sending data to API)
    // 現状はAPIから取得するのみなので未実装

    // MARK: - Mapping Error
    public enum MappingError: Error, LocalizedError {
        case invalidDateString(String)

        public var errorDescription: String? {
            switch self {
            case .invalidDateString(let dateString):
                return "無効な日付文字列です: \(dateString)"
            }
        }
    }
}
