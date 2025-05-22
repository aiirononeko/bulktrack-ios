import Foundation

public struct DashboardEntity: Equatable {
    public let thisWeek: WeekPointEntity
    public let lastWeek: WeekPointEntity
    public let trend: [WeekPointEntity]
    public let muscleGroups: [MuscleGroupSeriesEntity]
    public let metrics: [MetricSeriesEntity]

    public init(
        thisWeek: WeekPointEntity,
        lastWeek: WeekPointEntity,
        trend: [WeekPointEntity],
        muscleGroups: [MuscleGroupSeriesEntity],
        metrics: [MetricSeriesEntity]
    ) {
        self.thisWeek = thisWeek
        self.lastWeek = lastWeek
        self.trend = trend
        self.muscleGroups = muscleGroups
        self.metrics = metrics
    }
}

public struct MuscleGroupSeriesEntity: Identifiable, Equatable {
    public let id: Int // muscleGroupId を ID として使用
    public let muscleGroupId: Int
    public let groupName: String
    public let points: [MuscleGroupWeekPointEntity]

    public init(
        muscleGroupId: Int,
        groupName: String,
        points: [MuscleGroupWeekPointEntity]
    ) {
        self.id = muscleGroupId
        self.muscleGroupId = muscleGroupId
        self.groupName = groupName
        self.points = points
    }
}

public struct MuscleGroupWeekPointEntity: Identifiable, Equatable {
    public let id: String // weekStart を ID として使用
    public let weekStart: Date
    public let totalVolume: Double
    public let setCount: Int
    public let avgE1rm: Double?

    public init(
        weekStart: Date,
        totalVolume: Double,
        setCount: Int,
        avgE1rm: Double?
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.id = dateFormatter.string(from: weekStart)
        self.weekStart = weekStart
        self.totalVolume = totalVolume
        self.setCount = setCount
        self.avgE1rm = avgE1rm
    }
}

public struct MetricSeriesEntity: Identifiable, Equatable {
    public let id: String // metricKey を ID として使用
    public let metricKey: String
    public let unit: String
    public let points: [MetricPointEntity]

    public init(
        metricKey: String,
        unit: String,
        points: [MetricPointEntity]
    ) {
        self.id = metricKey
        self.metricKey = metricKey
        self.unit = unit
        self.points = points
    }
}

public struct MetricPointEntity: Identifiable, Equatable {
    public let id: String // weekStart を ID として使用
    public let weekStart: Date
    public let value: Double

    public init(
        weekStart: Date,
        value: Double
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.id = dateFormatter.string(from: weekStart)
        self.weekStart = weekStart
        self.value = value
    }
}
