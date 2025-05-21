import Foundation
import Security
import Domain // For AuthToken and SecureStorageServiceProtocol

public struct KeychainService: SecureStorageServiceProtocol {

    // Private struct to hold both token and its retrieval date for Keychain storage
    private struct KeychainAuthTokenInfo: Codable {
        let token: AuthToken
        let retrievedAt: Date
    }

    private let serviceIdentifier: String
    private let tokenInfoAccount = "authTokenInfo" // Changed account name to reflect new structure

    public init(serviceIdentifier: String = "com.bulktrack.authtokeninfo") { // Changed default service id slightly
        self.serviceIdentifier = serviceIdentifier
    }

    public func saveTokenInfo(token: AuthToken, retrievedAt: Date) throws {
        do {
            let tokenInfo = KeychainAuthTokenInfo(token: token, retrievedAt: retrievedAt)
            let data = try JSONEncoder().encode(tokenInfo)
            
            try? deleteKeychainItem() // Delete existing item before saving

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceIdentifier,
                kSecAttrAccount as String: tokenInfoAccount,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw SecureStorageError.saveFailed(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil))
            }
        } catch let error as SecureStorageError {
            throw error
        } catch {
            throw SecureStorageError.saveFailed(error)
        }
    }

    public func getTokenInfo() throws -> (token: AuthToken, retrievedAt: Date)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: tokenInfoAccount,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw SecureStorageError.unknown(nil)
            }
            do {
                let tokenInfo = try JSONDecoder().decode(KeychainAuthTokenInfo.self, from: data)
                return (token: tokenInfo.token, retrievedAt: tokenInfo.retrievedAt)
            } catch {
                // If decoding fails, it might be an old format or corrupted data.
                // Consider deleting the corrupted item.
                try? deleteKeychainItem()
                throw SecureStorageError.unknown(error) // Report as decoding error
            }
        case errSecItemNotFound:
            return nil
        default:
            throw SecureStorageError.unknown(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil))
        }
    }

    public func deleteTokenInfo() throws {
        try deleteKeychainItem()
    }
    
    private func deleteKeychainItem() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: tokenInfoAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        // Allow item not found, as we might call this defensively
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.deleteFailed(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil))
        }
    }
}
