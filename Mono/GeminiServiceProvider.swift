//
//  GeminiServiceProvider.swift
//  Mono
//
//  Google Gemini AI service provider implementation
//

import Foundation

final class GeminiServiceProvider: AIServiceProvider {
    let id = "gemini"
    let name = "Google Gemini"
    let description = "Google's advanced AI models"
    let supportedCapabilities: Set<AICapability> = [.chatCompletion]
    
    let availableModels: [AIModel] = [
        AIModel(
            id: "gemini-1.5-flash",
            name: "Gemini 1.5 Flash",
            description: "Fast and efficient for most tasks",
            capabilities: [.chatCompletion],
            contextWindow: 1000000,
            costTier: .low
        ),
        AIModel(
            id: "gemini-1.5-pro",
            name: "Gemini 1.5 Pro",
            description: "Most capable model for complex reasoning",
            capabilities: [.chatCompletion],
            contextWindow: 2000000,
            costTier: .medium
        ),
        AIModel(
            id: "gemini-2.0-flash-exp",
            name: "Gemini 2.0 Flash (Experimental)",
            description: "Latest experimental model with enhanced capabilities",
            capabilities: [.chatCompletion],
            contextWindow: 1000000,
            costTier: .medium
        )
    ]
    
    var isConfigured: Bool {
        return APIKeyManager.shared.hasAPIKey(for: id)
    }
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
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
        
        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert messages to Gemini format
        var contents: [[String: Any]] = []
        
        // Add system instruction if provided
        var systemInstruction: [String: Any]?
        if let systemPrompt = systemPrompt {
            systemInstruction = [
                "parts": [["text": systemPrompt]]
            ]
        }
        
        // Convert chat messages
        for message in messages {
            let role = message.isUser ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [["text": message.text]]
            ])
        }
        
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": 8192
            ]
        ]
        
        if let systemInstruction = systemInstruction {
            body["systemInstruction"] = systemInstruction
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    break
                case 400:
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    if bodyText.contains("API_KEY_INVALID") {
                        throw AIServiceError.invalidAPIKey(provider: name)
                    } else {
                        throw AIServiceError.invalidResponse("Bad request: \(bodyText)")
                    }
                case 429:
                    throw AIServiceError.rateLimitExceeded(provider: name)
                case 500...599:
                    throw AIServiceError.serviceUnavailable(provider: name)
                default:
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    throw AIServiceError.invalidResponse("HTTP \(httpResponse.statusCode): \(bodyText)")
                }
            }
            
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let candidate = decoded.candidates?.first,
                  let content = candidate.content,
                  let part = content.parts?.first,
                  let text = part.text, !text.isEmpty else {
                throw AIServiceError.invalidResponse("Empty response from Gemini")
            }
            
            return text
            
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

// MARK: - Gemini Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
    let role: String?
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiPromptFeedback: Codable {
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiSafetyRating: Codable {
    let category: String?
    let probability: String?
}
