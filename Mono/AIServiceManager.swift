//
//  AIServiceManager.swift
//  Mono
//
//  Central manager for AI service providers
//

import Foundation
import Combine

final class AIServiceManager: ObservableObject {
    static let shared = AIServiceManager()

    @Published var selectedProvider: String = "groq" {
        didSet {
            UserDefaults.standard.set(selectedProvider, forKey: "selected_ai_provider")
            // Update legacy llmModel setting for backward compatibility
            syncLegacyModelSetting()
        }
    }

    @Published var availableProviders: [String: AIServiceProvider] = [:]
    @Published var providerConfigurationStates: [String: Bool] = [:]

    private let apiKeyManager = APIKeyManager.shared

    private init() {
        registerProviders()
        apiKeyManager.migrateFromUserDefaults()
        refreshProviderStates()
        
        // Load saved provider preference
        if let savedProvider = UserDefaults.standard.string(forKey: "selected_ai_provider"),
           availableProviders[savedProvider] != nil {
            selectedProvider = savedProvider
        }

        // Listen for API key changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAPIKeyChange),
            name: .apiKeyDidChange,
            object: nil
        )
    }
    
    // MARK: - Provider Registration
    
    private func registerProviders() {
        // Register Groq and OpenAI providers
        let groqProvider = GroqServiceProvider()
        let openAIProvider = OpenAIServiceProvider()
        
        availableProviders[groqProvider.id] = groqProvider
        availableProviders[openAIProvider.id] = openAIProvider
        
        print("🤖 Registered AI providers: \(availableProviders.keys.sorted())")
        for (id, provider) in availableProviders {
            print("   - \(id): \(provider.name) (configured: \(provider.isConfigured))")
        }
    }
    
    // MARK: - Provider Access
    
    var currentProvider: AIServiceProvider? {
        return availableProviders[selectedProvider]
    }
    
    func getProvider(id: String) -> AIServiceProvider? {
        return availableProviders[id]
    }
    
    func getConfiguredProviders() -> [AIServiceProvider] {
        return availableProviders.values.filter { $0.isConfigured }
    }
    
    // MARK: - Chat Operations
    
    func sendChatMessage(
        messages: [ChatMessage],
        systemPrompt: String? = nil,
        temperature: Double = 0.7
    ) async throws -> String {
        guard let provider = currentProvider else {
            throw AIServiceError.serviceUnavailable(provider: "No provider selected")
        }
        
        guard provider.isConfigured else {
            throw AIServiceError.missingAPIKey(provider: provider.name)
        }
        
        // Get the selected model for this provider
        let selectedModel = getSelectedModel(for: provider.id)
        
        return try await provider.sendChatMessage(
            messages: messages,
            model: selectedModel,
            systemPrompt: systemPrompt,
            temperature: temperature
        )
    }
    
    // MARK: - Transcription Operations
    
    func transcribeAudio(
        audioData: Data,
        language: String? = nil
    ) async throws -> String {
        // For transcription, we prefer providers that support it
        let transcriptionProviders = availableProviders.values.filter {
            $0.supportedCapabilities.contains(.audioTranscription) && $0.isConfigured
        }
        
        guard let provider = transcriptionProviders.first ?? currentProvider else {
            throw AIServiceError.serviceUnavailable(provider: "No transcription provider available")
        }
        
        guard provider.isConfigured else {
            throw AIServiceError.missingAPIKey(provider: provider.name)
        }
        
        let selectedModel = getSelectedTranscriptionModel(for: provider.id)
        
        return try await provider.transcribeAudio(
            audioData: audioData,
            model: selectedModel,
            language: language
        )
    }
    
    // MARK: - Model Selection
    
    func getSelectedModel(for providerId: String) -> String {
        let key = "selected_model_\(providerId)"
        if let model = UserDefaults.standard.string(forKey: key) {
            return model
        }

        // For backward compatibility, check if this is the current provider and use legacy llmModel setting
        if providerId == selectedProvider {
            let legacyModel = UserDefaults.standard.string(forKey: "llm_model")
            if let legacyModel = legacyModel,
               let provider = availableProviders[providerId],
               provider.availableModels.contains(where: { $0.id == legacyModel }) {
                return legacyModel
            }
        }

        // Return default model for provider
        return availableProviders[providerId]?.availableModels.first?.id ?? ""
    }
    
    private func getSelectedTranscriptionModel(for providerId: String) -> String? {
        let key = "selected_transcription_model_\(providerId)"
        if let model = UserDefaults.standard.string(forKey: key) {
            return model
        }
        
        // Return default transcription model for provider
        return availableProviders[providerId]?.availableModels.first(where: {
            $0.capabilities.contains(.audioTranscription)
        })?.id
    }
    
    func setSelectedModel(_ modelId: String, for providerId: String) {
        let key = "selected_model_\(providerId)"
        UserDefaults.standard.set(modelId, forKey: key)

        // For backward compatibility, also update the legacy llmModel setting if this is the current provider
        if providerId == selectedProvider {
            UserDefaults.standard.set(modelId, forKey: "llm_model")
        }
    }
    
    func setSelectedTranscriptionModel(_ modelId: String, for providerId: String) {
        let key = "selected_transcription_model_\(providerId)"
        UserDefaults.standard.set(modelId, forKey: key)
    }
    
    // MARK: - Provider Status
    
    func getProviderStatus() -> [String: ProviderStatus] {
        var status: [String: ProviderStatus] = [:]
        
        for (id, provider) in availableProviders {
            status[id] = ProviderStatus(
                isConfigured: provider.isConfigured,
                hasValidKey: apiKeyManager.hasAPIKey(for: id),
                supportedCapabilities: provider.supportedCapabilities,
                modelCount: provider.availableModels.count
            )
        }
        
        return status
    }

    // MARK: - Legacy Compatibility

    private func syncLegacyModelSetting() {
        let currentModel = getSelectedModel(for: selectedProvider)
        UserDefaults.standard.set(currentModel, forKey: "llm_model")
    }

    // MARK: - Provider State Management

    @objc private func handleAPIKeyChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.refreshProviderStates()
        }
    }

    func refreshProviderStates() {
        var newStates: [String: Bool] = [:]
        for (id, provider) in availableProviders {
            newStates[id] = provider.isConfigured
        }
        providerConfigurationStates = newStates
    }

    func isProviderConfigured(_ providerId: String) -> Bool {
        return providerConfigurationStates[providerId] ?? false
    }
}

// MARK: - Provider Status

struct ProviderStatus {
    let isConfigured: Bool
    let hasValidKey: Bool
    let supportedCapabilities: Set<AICapability>
    let modelCount: Int
}
