//
//  MetricSeriesDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct MetricSeriesDTO: Codable {
    public let metricKey: String
    public let unit: String
    public let points: [MetricPointDTO]

    enum CodingKeys: String, CodingKey {
        case metricKey
        case unit
        case points
    }

    public init(metricKey: String, unit: String, points: [MetricPointDTO]) {
        self.metricKey = metricKey
        self.unit = unit
        self.points = points
    }
}
