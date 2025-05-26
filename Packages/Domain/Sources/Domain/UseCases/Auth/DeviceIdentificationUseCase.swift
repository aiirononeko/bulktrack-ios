//
//  DeviceIdentificationUseCase.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/26.
//

import Foundation

public struct DeviceIdentificationUseCase {
    private let deviceIdentifierService: DeviceIdentifierServiceProtocol
    
    public init(deviceIdentifierService: DeviceIdentifierServiceProtocol) {
        self.deviceIdentifierService = deviceIdentifierService
    }
    
    public func getOrCreateDeviceIdentity() -> DeviceIdentity {
        let identifier = deviceIdentifierService.getDeviceIdentifier()
        return DeviceIdentity(identifier: identifier)
    }
}
