//
//  ResultState.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public enum ResultState<Success, Failure: Error>: Equatable {
    case idle
    case loading
    case success(Success)
    case failure(Failure)

    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var successValue: Success? {
        if case .success(let value) = self { return value }
        return nil
    }

    public var failureError: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
    
    // Equatable conformance for Success type that is Equatable
    public static func == (lhs: ResultState<Success, Failure>, rhs: ResultState<Success, Failure>) -> Bool where Success: Equatable {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.success(let lVal), .success(let rVal)):
            return lVal == rVal
        case (.failure(let lErr), .failure(let rErr)):
            // Comparing errors can be tricky. For now, compare their localizedDescription.
            // For more robust comparison, Failure should conform to Equatable.
            return lErr.localizedDescription == rErr.localizedDescription
        default:
            return false
        }
    }

    // Equatable conformance for Success type that is NOT Equatable (always false for success cases)
    public static func == (lhs: ResultState<Success, Failure>, rhs: ResultState<Success, Failure>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.success, .success):
            // If Success is not Equatable, we can't compare the values.
            // Consider this as not equal, or implement specific logic if needed.
            // For simplicity in a general ResultState, this might be sufficient.
            // Alternatively, require Success to be Equatable or provide a comparator.
            return false // Or true if you consider two .success states without value comparison as equal
        case (.failure(let lErr), .failure(let rErr)):
            return lErr.localizedDescription == rErr.localizedDescription
        default:
            return false
        }
    }
}
