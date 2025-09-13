//
//  APIKeyManager.swift
//  Mono
//
//  Secure API key storage and management using iOS Keychain
//

import Foundation
import Security

final class APIKeyManager {
    static let shared = APIKeyManager()
    private init() {}
    
    private let service = "com.mono.apikeys"
    
    // MARK: - API Key Storage
    
    func setAPIKey(_ key: String, for provider: String) throws {
        let keyData = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecValueData as String: keyData
        ]
        
        // Delete existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw APIKeyError.storageError("Failed to store API key for \(provider)")
        }
    }
    
    func getAPIKey(for provider: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data,
              let key = String(data: keyData, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func removeAPIKey(for provider: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyError.storageError("Failed to remove API key for \(provider)")
        }
    }
    
    func hasAPIKey(for provider: String) -> Bool {
        return getAPIKey(for: provider) != nil
    }
    
    func getAllConfiguredProviders() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateFromUserDefaults() {
        // Migrate existing Groq API key from UserDefaults
        if let groqKey = UserDefaults.standard.string(forKey: "groq_api_key"),
           !groqKey.isEmpty {
            try? setAPIKey(groqKey, for: "groq")
            UserDefaults.standard.removeObject(forKey: "groq_api_key")
            print("✅ Migrated Groq API key to secure storage")
        }
    }
}

// MARK: - API Key Errors

enum APIKeyError: LocalizedError {
    case storageError(String)
    case retrievalError(String)
    
    var errorDescription: String? {
        switch self {
        case .storageError(let message):
            return "Storage error: \(message)"
        case .retrievalError(let message):
            return "Retrieval error: \(message)"
        }
    }
}
