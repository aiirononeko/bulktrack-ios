//
//  DeviceIdentity.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/26.
//

import Foundation

public struct DeviceIdentity {
    public let identifier: String
    public let createdAt: Date
    
    public init(identifier: String, createdAt: Date = Date()) {
        self.identifier = identifier
        self.createdAt = createdAt
    }
}
