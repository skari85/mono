//
//  OpenRouterServiceProvider.swift
//  Mono
//
//  OpenRouter service provider implementation
//

import Foundation

final class OpenRouterServiceProvider: AIServiceProvider {
    let id = "openrouter"
    let name = "OpenRouter"
    let description = "Access to multiple AI models through unified API"
    let supportedCapabilities: Set<AICapability> = [.chatCompletion]
    
    let availableModels: [AIModel] = [
        AIModel(
            id: "anthropic/claude-3.5-sonnet",
            name: "Claude 3.5 Sonnet",
            description: "Anthropic's most intelligent model",
            capabilities: [.chatCompletion],
            contextWindow: 200000,
            costTier: .high
        ),
        AIModel(
            id: "anthropic/claude-3-haiku",
            name: "Claude 3 Haiku",
            description: "Fast and affordable Claude model",
            capabilities: [.chatCompletion],
            contextWindow: 200000,
            costTier: .medium
        ),
        AIModel(
            id: "openai/gpt-4o",
            name: "GPT-4o (via OpenRouter)",
            description: "OpenAI's latest multimodal model",
            capabilities: [.chatCompletion],
            contextWindow: 128000,
            costTier: .high
        ),
        AIModel(
            id: "openai/gpt-4o-mini",
            name: "GPT-4o Mini (via OpenRouter)",
            description: "Affordable GPT-4 class model",
            capabilities: [.chatCompletion],
            contextWindow: 128000,
            costTier: .medium
        ),
        AIModel(
            id: "meta-llama/llama-3.1-70b-instruct",
            name: "Llama 3.1 70B",
            description: "Meta's powerful open-source model",
            capabilities: [.chatCompletion],
            contextWindow: 131072,
            costTier: .medium
        ),
        AIModel(
            id: "meta-llama/llama-3.1-8b-instruct",
            name: "Llama 3.1 8B",
            description: "Fast and efficient Llama model",
            capabilities: [.chatCompletion],
            contextWindow: 131072,
            costTier: .low
        ),
        AIModel(
            id: "google/gemini-pro-1.5",
            name: "Gemini Pro 1.5 (via OpenRouter)",
            description: "Google's advanced AI model",
            capabilities: [.chatCompletion],
            contextWindow: 2000000,
            costTier: .medium
        ),
        AIModel(
            id: "mistralai/mistral-large",
            name: "Mistral Large",
            description: "Mistral's flagship model",
            capabilities: [.chatCompletion],
            contextWindow: 128000,
            costTier: .medium
        )
    ]
    
    var isConfigured: Bool {
        return APIKeyManager.shared.hasAPIKey(for: id)
    }
    
    private let baseURL = "https://openrouter.ai/api/v1"
    
    // MARK: - Chat Completion
    
    func sendChatMessage(
        messages: [ChatMessage],
        model: String,
        systemPrompt: String?,
        temperature: Double
    ) async throws -> String {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: id) else {
            throw AIServiceError.missingAPIKey(provider: name)
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mono-iOS-App", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("https://mono-app.com", forHTTPHeaderField: "X-Title")
        
        // Convert messages to OpenRouter format (OpenAI-compatible)
        var apiMessages: [[String: String]] = []
        
        if let systemPrompt = systemPrompt {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }
        
        for message in messages {
            apiMessages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.text
            ])
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "temperature": temperature,
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    break
                case 401:
                    throw AIServiceError.invalidAPIKey(provider: name)
                case 402:
                    throw AIServiceError.insufficientCredits(provider: name)
                case 429:
                    throw AIServiceError.rateLimitExceeded(provider: name)
                case 400:
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    if bodyText.contains("model") {
                        throw AIServiceError.modelNotSupported(model: model, provider: name)
                    } else {
                        throw AIServiceError.invalidResponse("Bad request: \(bodyText)")
                    }
                case 500...599:
                    throw AIServiceError.serviceUnavailable(provider: name)
                default:
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    throw AIServiceError.invalidResponse("HTTP \(httpResponse.statusCode): \(bodyText)")
                }
            }
            
            let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
            
            guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
                throw AIServiceError.invalidResponse("Empty response from OpenRouter")
            }
            
            return content
            
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.networkError(error)
        }
    }
    
    // MARK: - Audio Transcription (Not supported)
    
    func transcribeAudio(
        audioData: Data,
        model: String?,
        language: String?
    ) async throws -> String {
        throw AIServiceError.modelNotSupported(model: "audio transcription", provider: name)
    }
}

// MARK: - OpenRouter Response Models

struct OpenRouterResponse: Codable {
    let choices: [OpenRouterChoice]
    let usage: OpenRouterUsage?
    let id: String?
    let model: String?
}

struct OpenRouterChoice: Codable {
    let message: OpenRouterMessage
    let finishReason: String?
    let index: Int?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
        case index
    }
}

struct OpenRouterMessage: Codable {
    let content: String
    let role: String
}

struct OpenRouterUsage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
