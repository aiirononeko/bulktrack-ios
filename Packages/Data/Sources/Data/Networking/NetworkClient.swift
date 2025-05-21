import Foundation

public protocol NetworkClientProtocol {
    func sendRequest<T: Decodable>(endpoint: Endpoint, decoder: JSONDecoder) async throws -> T
    func sendRequest(endpoint: Endpoint) async throws // For requests that don't return data (e.g., 204 No Content)
}

public struct NetworkClient: NetworkClientProtocol {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func sendRequest<T: Decodable>(endpoint: Endpoint, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        guard let urlRequest = endpoint.asURLRequest() else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.custom("Invalid HTTP response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                // Attempt to decode ErrorResponseDTO from the data. 'data' is non-optional here.
                if !data.isEmpty {
                    do {
                        let errorResponse = try decoder.decode(ErrorResponseDTO.self, from: data)
                        throw APIError.serverError(statusCode: httpResponse.statusCode, errorResponse: errorResponse)
                    } catch {
                        // If ErrorResponseDTO decoding fails, throw generic status code error with raw data
                        throw APIError.unexpectedStatusCode(statusCode: httpResponse.statusCode, data: data)
                    }
                } else {
                    // No data in error response
                    throw APIError.unexpectedStatusCode(statusCode: httpResponse.statusCode, data: nil)
                }
            }
            
            // The caller is responsible for configuring the decoder,
            // including its dateDecodingStrategy.
            // APIService, for example, passes a decoder already configured with .iso8601.

            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    public func sendRequest(endpoint: Endpoint) async throws {
        guard let urlRequest = endpoint.asURLRequest() else {
            throw APIError.invalidURL
        }

        do {
            // Capture data even for non-decodable requests to parse potential error bodies
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.custom("Invalid HTTP response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                // 'data' is non-optional here.
                if !data.isEmpty {
                    do {
                        // Use a default decoder for ErrorResponseDTO
                        let errorDecoder = JSONDecoder()
                        // errorDecoder.dateDecodingStrategy = .iso8601 // If ErrorResponseDTO had dates
                        let errorResponse = try errorDecoder.decode(ErrorResponseDTO.self, from: data)
                        throw APIError.serverError(statusCode: httpResponse.statusCode, errorResponse: errorResponse)
                    } catch {
                        throw APIError.unexpectedStatusCode(statusCode: httpResponse.statusCode, data: data)
                    }
                } else {
                    throw APIError.unexpectedStatusCode(statusCode: httpResponse.statusCode, data: nil)
                }
            }
            // If successful (e.g., 204 No Content), no further action needed for this variant.
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }
}

// Endpoint definition (can be in its own file or here for simplicity)
public protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get } // For query params or body
    var body: Data? { get } // For raw body data
}

public extension Endpoint {
    // Default implementations
    var baseURL: URL {
        // TODO: Make this configurable (e.g., via environment variables or a config file)
        // For now, using the local development server from OpenAPI spec.
        // Ensure this matches your actual API server URL.
        #if DEBUG
        return URL(string: "http://localhost:8787/v1")!
        #else
        return URL(string: "https://api.bulk-track.com/v1")!
        #endif
    }

    var headers: [String: String]? {
        // Default to Content-Type only. Authorization should be added by specific Endpoint implementations
        // or by APIService when creating the Endpoint, if authentication is required.
        return ["Content-Type": "application/json"]
    }
    
    var parameters: [String: Any]? { nil }
    var body: Data? { nil }

    func asURLRequest() -> URLRequest? {
        var url = baseURL.appendingPathComponent(path)

        if method == .get, let parameters = parameters as? [String: String] {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let newUrl = urlComponents?.url {
                url = newUrl
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let bodyData = body {
            request.httpBody = bodyData
        } else if method != .get, let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        return request
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    // Add other methods as needed
}
