//
//  DeviceIdentificationUseCaseTests.swift
//  DomainTests
//
//  Created by Ryota Katada on 2025/05/26.
//

import XCTest
@testable import Domain

final class DeviceIdentificationUseCaseTests: XCTestCase {
    
    private var sut: DeviceIdentificationUseCase!
    private var mockDeviceIdentifierService: MockDeviceIdentifierService!
    
    override func setUp() {
        super.setUp()
        mockDeviceIdentifierService = MockDeviceIdentifierService()
        sut = DeviceIdentificationUseCase(deviceIdentifierService: mockDeviceIdentifierService)
    }
    
    override func tearDown() {
        sut = nil
        mockDeviceIdentifierService = nil
        super.tearDown()
    }
    
    func testGetOrCreateDeviceIdentity() {
        // Given
        let expectedIdentifier = "test-device-id-123"
        mockDeviceIdentifierService.mockIdentifier = expectedIdentifier
        
        // When
        let result = sut.getOrCreateDeviceIdentity()
        
        // Then
        XCTAssertEqual(result.identifier, expectedIdentifier)
        XCTAssertTrue(mockDeviceIdentifierService.getDeviceIdentifierCalled)
        
        // createdAt should be recent (within last few seconds)
        let now = Date()
        XCTAssertLessThan(now.timeIntervalSince(result.createdAt), 5.0)
    }
    
    func testGetOrCreateDeviceIdentityWithEmptyIdentifier() {
        // Given
        let expectedIdentifier = ""
        mockDeviceIdentifierService.mockIdentifier = expectedIdentifier
        
        // When
        let result = sut.getOrCreateDeviceIdentity()
        
        // Then
        XCTAssertEqual(result.identifier, expectedIdentifier)
        XCTAssertTrue(mockDeviceIdentifierService.getDeviceIdentifierCalled)
    }
}

// MARK: - Mock Classes

private class MockDeviceIdentifierService: DeviceIdentifierServiceProtocol {
    var mockIdentifier: String = "default-mock-id"
    var getDeviceIdentifierCalled = false
    
    func getDeviceIdentifier() -> String {
        getDeviceIdentifierCalled = true
        return mockIdentifier
    }
}
