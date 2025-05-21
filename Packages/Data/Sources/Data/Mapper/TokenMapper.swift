import Foundation
import Domain // For AuthToken
import Data   // For TokenResponse DTO

public enum TokenMapper {

    public static func toEntity(dto: TokenResponse) -> AuthToken {
        return AuthToken(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresIn: dto.expiresIn
        )
    }

    // Optional: If mapping from Entity back to DTO is needed.
    // In this case, DTO and Entity are identical, so it would be direct.
    public static func toDTO(entity: AuthToken) -> TokenResponse {
        return TokenResponse(
            accessToken: entity.accessToken,
            refreshToken: entity.refreshToken,
            expiresIn: entity.expiresIn
        )
    }
}
