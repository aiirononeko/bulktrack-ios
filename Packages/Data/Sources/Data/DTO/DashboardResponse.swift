import Foundation

// MARK: - Main Dashboard Response DTO
public struct DashboardResponse: Codable {
    public let thisWeek: WeekPointDTO
    public let lastWeek: WeekPointDTO
    public let trend: [WeekPointDTO]
    public let muscleGroups: [MuscleGroupSeriesDTO]
    public let metrics: [MetricSeriesDTO]
}

// MARK: - Week Point DTO
public struct WeekPointDTO: Codable {
    public let weekStart: String // "YYYY-MM-DD"
    public let totalVolume: Double
    public let avgSetVolume: Double
    public let e1rmAvg: Double?
}

// MARK: - Muscle Group Series DTO
public struct MuscleGroupSeriesDTO: Codable {
    public let muscleGroupId: Int
    public let groupName: String
    public let points: [MuscleGroupWeekPointDTO]
}

// MARK: - Muscle Group Week Point DTO
public struct MuscleGroupWeekPointDTO: Codable {
    public let weekStart: String // "YYYY-MM-DD"
    public let totalVolume: Double
    public let setCount: Int
    public let avgE1rm: Double?
}

// MARK: - Metric Series DTO
public struct MetricSeriesDTO: Codable {
    public let metricKey: String
    public let unit: String
    public let points: [MetricPointDTO]
}

// MARK: - Metric Point DTO
public struct MetricPointDTO: Codable {
    public let weekStart: String // "YYYY-MM-DD"
    public let value: Double
}
