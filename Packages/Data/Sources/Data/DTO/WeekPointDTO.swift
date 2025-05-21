//
//  WeekPointDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct WeekPointDTO: Codable {
    public let weekStart: String // Format: YYYY-MM-DD
    public let totalVolume: Double
    public let avgSetVolume: Double
    public let e1rmAvg: Double?

    enum CodingKeys: String, CodingKey {
        case weekStart
        case totalVolume
        case avgSetVolume
        case e1rmAvg
    }

    public init(weekStart: String, totalVolume: Double, avgSetVolume: Double, e1rmAvg: Double?) {
        self.weekStart = weekStart
        self.totalVolume = totalVolume
        self.avgSetVolume = avgSetVolume
        self.e1rmAvg = e1rmAvg
    }
}
