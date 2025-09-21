//
//  OpenAIServiceProvider.swift
//  Mono
//
//  OpenAI service provider implementation
//

import Foundation

final class OpenAIServiceProvider: AIServiceProvider {
    let id = "openai"
    let name = "OpenAI"
    let description = "GPT models from OpenAI"
    let supportedCapabilities: Set<AICapability> = [.chatCompletion, .audioTranscription]
    
    let availableModels: [AIModel] = [
        AIModel(
            id: "gpt-4o",
            name: "GPT-4o",
            description: "Most advanced multimodal model",
            capabilities: [.chatCompletion],
            contextWindow: 128000,
            costTier: .high
        ),
        AIModel(
            id: "gpt-4o-mini",
            name: "GPT-4o Mini",
            description: "Affordable and intelligent small model",
            capabilities: [.chatCompletion],
            contextWindow: 128000,
            costTier: .medium
        ),
        AIModel(
            id: "gpt-4-turbo",
            name: "GPT-4 Turbo",
            description: "High-intelligence model for complex tasks",
            capabilities: [.chatCompletion],
            contextWindow: 128000,
            costTier: .high
        ),
        AIModel(
            id: "gpt-3.5-turbo",
            name: "GPT-3.5 Turbo",
            description: "Fast and affordable for simple tasks",
            capabilities: [.chatCompletion],
            contextWindow: 16385,
            costTier: .low
        ),
        AIModel(
            id: "whisper-1",
            name: "Whisper",
            description: "Speech recognition model",
            capabilities: [.audioTranscription],
            contextWindow: nil,
            costTier: .low
        )
    ]
    
    var isConfigured: Bool {
        return APIKeyManager.shared.hasAPIKey(for: id)
    }
    
    private let baseURL = "https://api.openai.com/v1"
    
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
        
        // Convert messages to OpenAI format
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
            "max_tokens": 4096,
            "stream": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AIServiceError.invalidResponse("Failed to encode request: \(error)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                let bodyText = String(data: data, encoding: .utf8) ?? ""

                switch httpResponse.statusCode {
                case 200:
                    break
                case 400:
                    if bodyText.contains("invalid_request_error") {
                        throw AIServiceError.invalidResponse("Invalid request: \(bodyText)")
                    } else {
                        throw AIServiceError.invalidResponse("Bad request: \(bodyText)")
                    }
                case 401:
                    throw AIServiceError.invalidAPIKey(provider: name)
                case 429:
                    throw AIServiceError.rateLimitExceeded(provider: name)
                case 402:
                    throw AIServiceError.insufficientCredits(provider: name)
                case 500...599:
                    throw AIServiceError.serviceUnavailable(provider: name)
                default:
                    throw AIServiceError.invalidResponse("HTTP \(httpResponse.statusCode): \(bodyText)")
                }
            }

            // Debug: Print response for troubleshooting
            if let responseString = String(data: data, encoding: .utf8) {
                print("OpenAI Response: \(responseString)")
            }

            let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

            guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
                throw AIServiceError.invalidResponse("Empty response from OpenAI")
            }

            return content

        } catch let error as AIServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw AIServiceError.invalidResponse("Failed to decode OpenAI response: \(decodingError)")
        } catch {
            throw AIServiceError.networkError(error)
        }
    }
    
    // MARK: - Audio Transcription
    
    func transcribeAudio(
        audioData: Data,
        model: String?,
        language: String?
    ) async throws -> String {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: id) else {
            throw AIServiceError.missingAPIKey(provider: name)
        }
        
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model field
        let modelToUse = model ?? "whisper-1"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(modelToUse)\r\n".data(using: .utf8)!)
        
        // Add language field if specified
        if let language = language, !language.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    break
                case 401:
                    throw AIServiceError.invalidAPIKey(provider: name)
                case 429:
                    throw AIServiceError.rateLimitExceeded(provider: name)
                case 402:
                    throw AIServiceError.insufficientCredits(provider: name)
                case 500...599:
                    throw AIServiceError.serviceUnavailable(provider: name)
                default:
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    throw AIServiceError.invalidResponse("HTTP \(httpResponse.statusCode): \(bodyText)")
                }
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                return text
            } else {
                throw AIServiceError.invalidResponse("Invalid transcription response format")
            }
            
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.audioProcessingFailed(error)
        }
    }
}

// MARK: - OpenAI Response Models

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct OpenAIMessage: Codable {
    let content: String
    let role: String
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
