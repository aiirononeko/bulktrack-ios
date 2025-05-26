//
//  EnhancedDeviceIdentifierServiceTests.swift
//  DataTests
//
//  Created by Ryota Katada on 2025/05/26.
//

import XCTest
import Foundation
@testable import Data

final class EnhancedDeviceIdentifierServiceTests: XCTestCase {
    
    private var sut: EnhancedDeviceIdentifierService!
    private var mockKeychainStorage: MockDeviceIdentifierKeychain!
    private var mockUserDefaults: MockUserDefaults!
    
    override func setUp() {
        super.setUp()
        mockKeychainStorage = MockDeviceIdentifierKeychain()
        mockUserDefaults = MockUserDefaults()
        sut = EnhancedDeviceIdentifierService(
            keychainStorage: mockKeychainStorage,
            userDefaults: mockUserDefaults
        )
    }
    
    override func tearDown() {
        sut = nil
        mockKeychainStorage = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    func testGetDeviceIdentifierFromKeychain() {
        // Given
        let expectedId = "keychain-device-id"
        mockKeychainStorage.mockDeviceIdentifier = expectedId
        
        // When
        let result = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertEqual(result, expectedId)
        XCTAssertTrue(mockKeychainStorage.getDeviceIdentifierCalled)
        XCTAssertFalse(mockUserDefaults.stringForKeyCalled)
    }
    
    func testMigrateFromUserDefaultsToKeychain() {
        // Given
        let userDefaultsId = "userdefaults-device-id"
        mockKeychainStorage.mockDeviceIdentifier = nil
        mockUserDefaults.mockStringValue = userDefaultsId
        
        // When
        let result = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertEqual(result, userDefaultsId)
        XCTAssertTrue(mockKeychainStorage.getDeviceIdentifierCalled)
        XCTAssertTrue(mockUserDefaults.stringForKeyCalled)
        XCTAssertTrue(mockKeychainStorage.saveDeviceIdentifierCalled)
        XCTAssertEqual(mockKeychainStorage.savedIdentifier, userDefaultsId)
        XCTAssertTrue(mockUserDefaults.removeObjectForKeyCalled)
    }
    
    func testMigrationFailureFallbackToUserDefaults() {
        // Given
        let userDefaultsId = "userdefaults-device-id"
        mockKeychainStorage.mockDeviceIdentifier = nil
        mockKeychainStorage.shouldThrowOnSave = true
        mockUserDefaults.mockStringValue = userDefaultsId
        
        // When
        let result = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertEqual(result, userDefaultsId)
        XCTAssertTrue(mockKeychainStorage.saveDeviceIdentifierCalled)
        XCTAssertFalse(mockUserDefaults.removeObjectForKeyCalled) // Migration failed, so no removal
    }
    
    func testGenerateNewIdentifier() {
        // Given
        mockKeychainStorage.mockDeviceIdentifier = nil
        mockUserDefaults.mockStringValue = nil
        
        // When
        let result = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(mockKeychainStorage.getDeviceIdentifierCalled)
        XCTAssertTrue(mockUserDefaults.stringForKeyCalled)
        XCTAssertTrue(mockKeychainStorage.saveDeviceIdentifierCalled)
        XCTAssertEqual(mockKeychainStorage.savedIdentifier, result)
    }
    
    func testGenerateNewIdentifierWithKeychainFailure() {
        // Given
        mockKeychainStorage.mockDeviceIdentifier = nil
        mockKeychainStorage.shouldThrowOnSave = true
        mockUserDefaults.mockStringValue = nil
        
        // When
        let result = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(mockKeychainStorage.saveDeviceIdentifierCalled)
        XCTAssertTrue(mockUserDefaults.setValueCalled)
        XCTAssertEqual(mockUserDefaults.setValue, result)
    }
}

// MARK: - Mock Classes

private class MockDeviceIdentifierKeychain: DeviceIdentifierKeychainProtocol {
    var mockDeviceIdentifier: String?
    var shouldThrowOnSave = false
    var shouldThrowOnDelete = false
    
    // Call tracking
    var getDeviceIdentifierCalled = false
    var saveDeviceIdentifierCalled = false
    var deleteDeviceIdentifierCalled = false
    var savedIdentifier: String?
    
    func getDeviceIdentifier() -> String? {
        getDeviceIdentifierCalled = true
        return mockDeviceIdentifier
    }
    
    func saveDeviceIdentifier(_ identifier: String) throws {
        saveDeviceIdentifierCalled = true
        savedIdentifier = identifier
        if shouldThrowOnSave {
            throw DeviceIdentifierError.saveFailed
        }
    }
    
    func deleteDeviceIdentifier() throws {
        deleteDeviceIdentifierCalled = true
        if shouldThrowOnDelete {
            throw DeviceIdentifierError.deleteFailed
        }
    }
}

private class MockUserDefaults: UserDefaults {
    var mockStringValue: String?
    
    // Call tracking
    var stringForKeyCalled = false
    var setValueCalled = false
    var removeObjectForKeyCalled = false
    var setValue: String?
    var setKey: String?
    
    override func string(forKey defaultName: String) -> String? {
        stringForKeyCalled = true
        return mockStringValue
    }
    
    override func set(_ value: Any?, forKey defaultName: String) {
        if let stringValue = value as? String {
            setValueCalled = true
            setValue = stringValue
            setKey = defaultName
        }
    }
    
    override func removeObject(forKey defaultName: String) {
        removeObjectForKeyCalled = true
    }
}
