//
//  AIServiceTests.swift
//  MonoTests
//
//  Unit tests for the multi-provider AI service system
//

import XCTest
@testable import Mono

final class AIServiceTests: XCTestCase {
    
    var apiKeyManager: APIKeyManager!
    var aiServiceManager: AIServiceManager!
    
    override func setUpWithError() throws {
        apiKeyManager = APIKeyManager.shared
        aiServiceManager = AIServiceManager.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up test API keys
        try? apiKeyManager.removeAPIKey(for: "test_provider")
    }
    
    // MARK: - API Key Manager Tests
    
    func testAPIKeyStorage() throws {
        let testKey = "test_api_key_12345"
        let provider = "test_provider"
        
        // Test storing API key
        try apiKeyManager.setAPIKey(testKey, for: provider)
        
        // Test retrieving API key
        let retrievedKey = apiKeyManager.getAPIKey(for: provider)
        XCTAssertEqual(retrievedKey, testKey, "Retrieved API key should match stored key")
        
        // Test hasAPIKey
        XCTAssertTrue(apiKeyManager.hasAPIKey(for: provider), "Should have API key for provider")
        
        // Test removing API key
        try apiKeyManager.removeAPIKey(for: provider)
        XCTAssertFalse(apiKeyManager.hasAPIKey(for: provider), "Should not have API key after removal")
        XCTAssertNil(apiKeyManager.getAPIKey(for: provider), "Should return nil after removal")
    }
    
    func testAPIKeyIsolation() throws {
        let key1 = "key_for_provider_1"
        let key2 = "key_for_provider_2"
        let provider1 = "provider_1"
        let provider2 = "provider_2"
        
        // Store keys for different providers
        try apiKeyManager.setAPIKey(key1, for: provider1)
        try apiKeyManager.setAPIKey(key2, for: provider2)
        
        // Verify isolation
        XCTAssertEqual(apiKeyManager.getAPIKey(for: provider1), key1)
        XCTAssertEqual(apiKeyManager.getAPIKey(for: provider2), key2)
        
        // Remove one key, verify the other remains
        try apiKeyManager.removeAPIKey(for: provider1)
        XCTAssertNil(apiKeyManager.getAPIKey(for: provider1))
        XCTAssertEqual(apiKeyManager.getAPIKey(for: provider2), key2)
        
        // Cleanup
        try apiKeyManager.removeAPIKey(for: provider2)
    }
    
    // MARK: - AI Service Manager Tests
    
    func testProviderRegistration() {
        // Test that all expected providers are registered
        let expectedProviders = ["groq", "openai", "gemini", "openrouter"]
        
        for providerId in expectedProviders {
            XCTAssertNotNil(aiServiceManager.getProvider(id: providerId), "Provider \(providerId) should be registered")
        }
    }
    
    func testProviderSelection() {
        let originalProvider = aiServiceManager.selectedProvider
        
        // Test changing provider
        aiServiceManager.selectedProvider = "openai"
        XCTAssertEqual(aiServiceManager.selectedProvider, "openai")
        XCTAssertEqual(aiServiceManager.currentProvider?.id, "openai")
        
        // Restore original provider
        aiServiceManager.selectedProvider = originalProvider
    }
    
    func testProviderCapabilities() {
        // Test Groq provider capabilities
        if let groqProvider = aiServiceManager.getProvider(id: "groq") {
            XCTAssertTrue(groqProvider.supportedCapabilities.contains(.chatCompletion))
            XCTAssertTrue(groqProvider.supportedCapabilities.contains(.audioTranscription))
        }
        
        // Test OpenAI provider capabilities
        if let openAIProvider = aiServiceManager.getProvider(id: "openai") {
            XCTAssertTrue(openAIProvider.supportedCapabilities.contains(.chatCompletion))
            XCTAssertTrue(openAIProvider.supportedCapabilities.contains(.audioTranscription))
        }
        
        // Test Gemini provider capabilities
        if let geminiProvider = aiServiceManager.getProvider(id: "gemini") {
            XCTAssertTrue(geminiProvider.supportedCapabilities.contains(.chatCompletion))
            XCTAssertFalse(geminiProvider.supportedCapabilities.contains(.audioTranscription))
        }
        
        // Test OpenRouter provider capabilities
        if let openRouterProvider = aiServiceManager.getProvider(id: "openrouter") {
            XCTAssertTrue(openRouterProvider.supportedCapabilities.contains(.chatCompletion))
            XCTAssertFalse(openRouterProvider.supportedCapabilities.contains(.audioTranscription))
        }
    }
    
    func testProviderModels() {
        // Test that providers have models
        for (_, provider) in aiServiceManager.availableProviders {
            XCTAssertFalse(provider.availableModels.isEmpty, "\(provider.name) should have available models")
            
            // Test that each model has required properties
            for model in provider.availableModels {
                XCTAssertFalse(model.id.isEmpty, "Model ID should not be empty")
                XCTAssertFalse(model.name.isEmpty, "Model name should not be empty")
                XCTAssertFalse(model.description.isEmpty, "Model description should not be empty")
                XCTAssertFalse(model.capabilities.isEmpty, "Model should have at least one capability")
            }
        }
    }
    
    // MARK: - AI Model Tests
    
    func testAIModelProperties() {
        let model = AIModel(
            id: "test-model",
            name: "Test Model",
            description: "A test model",
            capabilities: [.chatCompletion],
            contextWindow: 4096,
            costTier: .medium
        )
        
        XCTAssertEqual(model.id, "test-model")
        XCTAssertEqual(model.name, "Test Model")
        XCTAssertEqual(model.description, "A test model")
        XCTAssertTrue(model.capabilities.contains(.chatCompletion))
        XCTAssertEqual(model.contextWindow, 4096)
        XCTAssertEqual(model.costTier, .medium)
    }
    
    // MARK: - Error Handling Tests
    
    func testAIServiceErrorMessages() {
        let errors: [AIServiceError] = [
            .missingAPIKey(provider: "TestProvider"),
            .invalidAPIKey(provider: "TestProvider"),
            .rateLimitExceeded(provider: "TestProvider"),
            .modelNotSupported(model: "test-model", provider: "TestProvider"),
            .insufficientCredits(provider: "TestProvider"),
            .serviceUnavailable(provider: "TestProvider")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription, "Error should have localized description")
            XCTAssertFalse(error.localizedDescription!.isEmpty, "Error description should not be empty")
        }
    }
    
    // MARK: - Provider Status Tests
    
    func testProviderStatus() {
        let status = aiServiceManager.getProviderStatus()
        
        // Test that status is returned for all providers
        for (providerId, _) in aiServiceManager.availableProviders {
            XCTAssertNotNil(status[providerId], "Status should be available for provider \(providerId)")
        }
        
        // Test status properties
        for (_, providerStatus) in status {
            XCTAssertGreaterThanOrEqual(providerStatus.modelCount, 0, "Model count should be non-negative")
            XCTAssertFalse(providerStatus.supportedCapabilities.isEmpty, "Should have at least one capability")
        }
    }
    
    // MARK: - Configuration Tests
    
    func testProviderConfiguration() throws {
        let testProvider = "groq"
        let testKey = "test_groq_key"
        
        // Initially should not be configured
        let provider = aiServiceManager.getProvider(id: testProvider)
        XCTAssertNotNil(provider)
        
        // Configure with API key
        try apiKeyManager.setAPIKey(testKey, for: testProvider)
        
        // Should now be configured
        XCTAssertTrue(provider!.isConfigured, "Provider should be configured after setting API key")
        
        // Cleanup
        try apiKeyManager.removeAPIKey(for: testProvider)
        XCTAssertFalse(provider!.isConfigured, "Provider should not be configured after removing API key")
    }
    
    func testConfiguredProviders() throws {
        let testProvider = "openai"
        let testKey = "test_openai_key"
        
        let initialCount = aiServiceManager.getConfiguredProviders().count
        
        // Configure a provider
        try apiKeyManager.setAPIKey(testKey, for: testProvider)
        
        let configuredProviders = aiServiceManager.getConfiguredProviders()
        XCTAssertEqual(configuredProviders.count, initialCount + 1, "Should have one more configured provider")
        
        let configuredIds = configuredProviders.map { $0.id }
        XCTAssertTrue(configuredIds.contains(testProvider), "Should include the configured provider")
        
        // Cleanup
        try apiKeyManager.removeAPIKey(for: testProvider)
    }
}
