//
//  AIServiceTypes.swift
//  Mono
//
//  Core types and protocols for multi-provider AI service integration
//

import Foundation

// MARK: - AI Service Provider Protocol

protocol AIServiceProvider {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var supportedCapabilities: Set<AICapability> { get }
    var availableModels: [AIModel] { get }
    var isConfigured: Bool { get }

    func sendChatMessage(
        messages: [ChatMessage],
        model: String,
        systemPrompt: String?,
        temperature: Double
    ) async throws -> String

    func transcribeAudio(
        audioData: Data,
        model: String?,
        language: String?
    ) async throws -> String
}

// MARK: - AI Capabilities

enum AICapability: String, CaseIterable, Codable {
    case chatCompletion = "chat_completion"
    case audioTranscription = "audio_transcription"
    case textSummarization = "text_summarization"
}

// MARK: - AI Model

struct AIModel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let capabilities: Set<AICapability>
    let contextWindow: Int?
    let costTier: CostTier

    enum CostTier: String, Codable, CaseIterable {
        case free = "free"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case premium = "premium"
    }

    // Custom Codable implementation to handle Set<AICapability>
    enum CodingKeys: String, CodingKey {
        case id, name, description, capabilities, contextWindow, costTier
    }

    init(id: String, name: String, description: String, capabilities: Set<AICapability>, contextWindow: Int?, costTier: CostTier) {
        self.id = id
        self.name = name
        self.description = description
        self.capabilities = capabilities
        self.contextWindow = contextWindow
        self.costTier = costTier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        let capabilitiesArray = try container.decode([AICapability].self, forKey: .capabilities)
        capabilities = Set(capabilitiesArray)
        contextWindow = try container.decodeIfPresent(Int.self, forKey: .contextWindow)
        costTier = try container.decode(CostTier.self, forKey: .costTier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(Array(capabilities), forKey: .capabilities)
        try container.encodeIfPresent(contextWindow, forKey: .contextWindow)
        try container.encode(costTier, forKey: .costTier)
    }
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case missingAPIKey(provider: String)
    case invalidAPIKey(provider: String)
    case networkError(Error)
    case invalidResponse(String)
    case rateLimitExceeded(provider: String)
    case modelNotSupported(model: String, provider: String)
    case insufficientCredits(provider: String)
    case serviceUnavailable(provider: String)
    case audioProcessingFailed(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "Please set your \(provider) API key in Settings"
        case .invalidAPIKey(let provider):
            return "Invalid \(provider) API key. Please check your credentials."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .rateLimitExceeded(let provider):
            return "\(provider) rate limit exceeded. Please try again later."
        case .modelNotSupported(let model, let provider):
            return "Model '\(model)' is not supported by \(provider)"
        case .insufficientCredits(let provider):
            return "Insufficient credits for \(provider). Please check your account."
        case .serviceUnavailable(let provider):
            return "\(provider) service is currently unavailable"
        case .audioProcessingFailed(let error):
            return "Audio processing failed: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Legacy Groq Response (for backward compatibility)

struct GroqResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }

    let choices: [Choice]
}
