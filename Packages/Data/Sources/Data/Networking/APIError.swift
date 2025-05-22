import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Error) // Underlying network error, e.g., no internet
    case unexpectedStatusCode(statusCode: Int, data: Data?) // HTTP error without specific ErrorResponseDTO
    case serverError(statusCode: Int, errorResponse: ErrorResponseDTO) // HTTP error with ErrorResponseDTO
    case decodingError(Error) // Error parsing successful response
    case noData // Successful response but no data when data was expected
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです。"
        case .requestFailed(let error):
            return "リクエストに失敗しました: \(error.localizedDescription)"
        case .unexpectedStatusCode(let statusCode, _):
            return "サーバーエラーが発生しました (コード: \(statusCode))。"
        case .serverError(_, let errorResponse):
            // TODO: Potentially use errorResponse.code for more specific client-side messages
            return "サーバーエラー: \(errorResponse.message) (コード: \(errorResponse.code))"
        case .decodingError(let error):
            return "受信データの解析に失敗しました: \(error.localizedDescription)"
        case .noData:
            return "サーバーからデータが返されませんでした。"
        case .custom(let message):
            return message
        }
    }

    // Helper to access server error details if available
    public var serverErrorDetails: ErrorResponseDTO? {
        if case .serverError(_, let details) = self {
            return details
        }
        return nil
    }
    
    public var httpStatusCode: Int? {
        switch self {
        case .unexpectedStatusCode(let statusCode, _):
            return statusCode
        case .serverError(let statusCode, _):
            return statusCode
        default:
            return nil
        }
    }

    // Computed property to get a string representation of server error details
    public var detailedServerErrorInfo: String? {
        guard let details = serverErrorDetails else { return nil }
        // ErrorResponseDTO only has code and message
        return "Code: \(details.code), Message: \"\(details.message)\""
    }

    // MARK: - Error Classification Helpers

    /// Checks if the error indicates an invalid refresh token (e.g., "invalid_grant").
    /// This needs to be tailored to the specific error codes/messages your backend returns.
    public func isInvalidGrantError() -> Bool {
        switch self {
        case .serverError(let statusCode, let errorResponse):
            // Common OAuth2 "invalid_grant" error, often with 400 or 401
            if (statusCode == 400 || statusCode == 401) {
                // Assuming ErrorResponseDTO.code might hold "invalid_grant" or similar
                // Or the message might contain indicative keywords.
                // This is highly dependent on your backend's error response structure.
                let errorCode = errorResponse.code.lowercased()
                let errorMessage = errorResponse.message.lowercased()
                if errorCode == "invalid_grant" || errorCode == "invalid_token" || errorCode == "token_expired" || errorCode == "invalid_refresh_token" {
                    return true
                }
                if errorMessage.contains("invalid_grant") || errorMessage.contains("invalid refresh token") || errorMessage.contains("expired refresh token") {
                    return true
                }
            }
            // Add more specific checks based on your backend's error codes for invalid/expired refresh tokens
        default:
            return false
        }
        return false
    }

    /// Checks if the error is likely a temporary network issue that can be retried.
    public func isRetryableNetworkError() -> Bool {
        switch self {
        case .requestFailed(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet,
                     .timedOut,
                     .cannotFindHost,
                     .cannotConnectToHost,
                     .networkConnectionLost,
                     .dnsLookupFailed,
                     .resourceUnavailable, // Could be temporary
                     .internationalRoamingOff, // If applicable
                     .secureConnectionFailed: // Sometimes temporary
                    return true
                default:
                    return false
                }
            }
            return false // Other non-URLError request failures might not be retryable
        case .unexpectedStatusCode(let statusCode, _),
             .serverError(let statusCode, _):
            // Retry on 5xx server errors (temporary issues)
            // Optionally, include 408 (Request Timeout) or 429 (Too Many Requests) if your retry logic handles them
            return (500...599).contains(statusCode)
        default:
            // .invalidURL, .decodingError, .noData, .custom are generally not retryable network errors
            return false
        }
    }
}
