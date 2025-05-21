//
//  TokenResponse.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public struct TokenResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresIn
    }

    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
