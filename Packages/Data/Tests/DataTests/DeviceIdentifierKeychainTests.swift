//
//  DeviceIdentifierKeychainTests.swift
//  DataTests
//
//  Created by Ryota Katada on 2025/05/26.
//

import XCTest
@testable import Data

final class DeviceIdentifierKeychainTests: XCTestCase {
    
    private var sut: DeviceIdentifierKeychain!
    private let testServiceIdentifier = "com.bulktrack.test.deviceidentifier"
    
    override func setUp() {
        super.setUp()
        sut = DeviceIdentifierKeychain(serviceIdentifier: testServiceIdentifier)
        // テスト開始時にキーチェーンをクリア
        try? sut.deleteDeviceIdentifier()
    }
    
    override func tearDown() {
        // テスト終了時にキーチェーンをクリア
        try? sut.deleteDeviceIdentifier()
        sut = nil
        super.tearDown()
    }
    
    func testSaveAndGetDeviceIdentifier() throws {
        // Given
        let testIdentifier = "test-device-id-123"
        
        // When
        try sut.saveDeviceIdentifier(testIdentifier)
        let retrievedIdentifier = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertEqual(retrievedIdentifier, testIdentifier)
    }
    
    func testGetDeviceIdentifierWhenNoneExists() {
        // Given - キーチェーンに何も保存されていない状態
        
        // When
        let retrievedIdentifier = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertNil(retrievedIdentifier)
    }
    
    func testDeleteDeviceIdentifier() throws {
        // Given
        let testIdentifier = "test-device-id-456"
        try sut.saveDeviceIdentifier(testIdentifier)
        
        // When
        try sut.deleteDeviceIdentifier()
        let retrievedIdentifier = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertNil(retrievedIdentifier)
    }
    
    func testOverwriteExistingIdentifier() throws {
        // Given
        let firstIdentifier = "first-id"
        let secondIdentifier = "second-id"
        
        // When
        try sut.saveDeviceIdentifier(firstIdentifier)
        try sut.saveDeviceIdentifier(secondIdentifier)
        let retrievedIdentifier = sut.getDeviceIdentifier()
        
        // Then
        XCTAssertEqual(retrievedIdentifier, secondIdentifier)
    }
    
    func testDeleteNonExistentIdentifier() {
        // Given - キーチェーンに何も保存されていない状態
        
        // When & Then - エラーが投げられないことを確認
        XCTAssertNoThrow(try sut.deleteDeviceIdentifier())
    }
}
