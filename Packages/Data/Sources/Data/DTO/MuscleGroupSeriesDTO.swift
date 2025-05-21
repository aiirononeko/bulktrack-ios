//
//  MuscleGroupSeriesDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct MuscleGroupSeriesDTO: Codable {
    public let muscleGroupId: Int
    public let groupName: String
    public let points: [MuscleGroupWeekPointDTO]

    enum CodingKeys: String, CodingKey {
        case muscleGroupId
        case groupName
        case points
    }

    public init(muscleGroupId: Int, groupName: String, points: [MuscleGroupWeekPointDTO]) {
        self.muscleGroupId = muscleGroupId
        self.groupName = groupName
        self.points = points
    }
}
