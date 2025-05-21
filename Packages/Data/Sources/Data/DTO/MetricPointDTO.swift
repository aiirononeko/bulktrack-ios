//
//  MetricPointDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct MetricPointDTO: Codable {
    public let weekStart: String // Format: YYYY-MM-DD
    public let value: Double

    enum CodingKeys: String, CodingKey {
        case weekStart
        case value
    }

    public init(weekStart: String, value: Double) {
        self.weekStart = weekStart
        self.value = value
    }
}
