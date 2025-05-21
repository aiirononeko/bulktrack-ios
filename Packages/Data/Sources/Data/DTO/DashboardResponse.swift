//
//  DashboardResponse.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct DashboardResponse: Codable {
    public let thisWeek: WeekPointDTO
    public let lastWeek: WeekPointDTO
    public let trend: [WeekPointDTO]
    public let muscleGroups: [MuscleGroupSeriesDTO]
    public let metrics: [MetricSeriesDTO]

    enum CodingKeys: String, CodingKey {
        case thisWeek
        case lastWeek
        case trend
        case muscleGroups
        case metrics
    }

    public init(thisWeek: WeekPointDTO, lastWeek: WeekPointDTO, trend: [WeekPointDTO], muscleGroups: [MuscleGroupSeriesDTO], metrics: [MetricSeriesDTO]) {
        self.thisWeek = thisWeek
        self.lastWeek = lastWeek
        self.trend = trend
        self.muscleGroups = muscleGroups
        self.metrics = metrics
    }
}
