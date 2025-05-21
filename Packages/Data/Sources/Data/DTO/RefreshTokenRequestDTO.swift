import Foundation

public struct RefreshTokenRequestDTO: Codable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
