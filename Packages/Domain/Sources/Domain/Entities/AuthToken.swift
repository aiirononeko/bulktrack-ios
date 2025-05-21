import Foundation

public struct AuthToken: Equatable, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int // Typically seconds until expiry

    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
