//
//  GroqServiceProvider.swift
//  Mono
//
//  Groq AI service provider implementation
//

import Foundation

final class GroqServiceProvider: AIServiceProvider {
    let id = "groq"
    let name = "Groq"
    let description = "Fast inference with Llama models"
    let supportedCapabilities: Set<AICapability> = [.chatCompletion, .audioTranscription]
    
    let availableModels: [AIModel] = [
        AIModel(
            id: "llama-3.1-8b-instant",
            name: "Llama 3.1 8B (Instant)",
            description: "Fast and efficient for most tasks",
            capabilities: [.chatCompletion],
            contextWindow: 8192,
            costTier: .low
        ),
        AIModel(
            id: "llama-3.1-70b",
            name: "Llama 3.1 70B (Quality)",
            description: "Higher quality responses, slower inference",
            capabilities: [.chatCompletion],
            contextWindow: 8192,
            costTier: .medium
        ),
        AIModel(
            id: "whisper-large-v3-turbo",
            name: "Whisper Large V3 Turbo",
            description: "Fast and accurate speech recognition",
            capabilities: [.audioTranscription],
            contextWindow: nil,
            costTier: .low
        )
    ]
    
    var isConfigured: Bool {
        return APIKeyManager.shared.hasAPIKey(for: id)
    }
    
    private let baseURL = "https://api.groq.com/openai/v1"
    
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
        
        // Convert messages to API format
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
            "temperature": temperature
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
                print("Groq Response: \(responseString)")
            }
            
            let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
            
            guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
                throw AIServiceError.invalidResponse("Empty response from Groq")
            }
            
            return content
            
        } catch let error as AIServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw AIServiceError.invalidResponse("Failed to decode Groq response: \(decodingError)")
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
        let modelToUse = model ?? "whisper-large-v3-turbo"
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
