//
//  MuscleGroupWeekPointDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct MuscleGroupWeekPointDTO: Codable {
    public let weekStart: String // Format: YYYY-MM-DD
    public let totalVolume: Double
    public let setCount: Int
    public let avgE1rm: Double?

    enum CodingKeys: String, CodingKey {
        case weekStart
        case totalVolume
        case setCount
        case avgE1rm
    }

    public init(weekStart: String, totalVolume: Double, setCount: Int, avgE1rm: Double?) {
        self.weekStart = weekStart
        self.totalVolume = totalVolume
        self.setCount = setCount
        self.avgE1rm = avgE1rm
    }
}
