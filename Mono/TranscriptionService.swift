//  TranscriptionService.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import Foundation

struct TranscriptionResult: Decodable {
    let text: String
}

enum TranscriptionError: Error {
    case missingAPIKey
    case fileNotFound
    case invalidResponse
}

class TranscriptionService {
    static let shared = TranscriptionService()
    private init() {}

    func transcribeAudio(messageId: UUID, language: String? = nil) async throws -> String {
        // Locate audio file saved by AudioManager
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(messageId.uuidString).m4a")
        guard FileManager.default.fileExists(atPath: audioURL.path) else { throw TranscriptionError.fileNotFound }

        // Load audio data
        guard let audioData = try? Data(contentsOf: audioURL) else {
            throw TranscriptionError.fileNotFound
        }

        // Use the new AI service manager for transcription
        return try await AIServiceManager.shared.transcribeAudio(
            audioData: audioData,
            language: language
        )
    }

    // Legacy method for backward compatibility
    func transcribeGroqWhisper(messageId: UUID, model: String = "whisper-large-v3-turbo", language: String? = nil) async throws -> String {
        return try await transcribeAudio(messageId: messageId, language: language)
    }

    private func transcribeGroqWhisperLegacy(messageId: UUID, model: String = "whisper-large-v3-turbo", language: String? = nil) async throws -> String {
        // Locate audio file saved by AudioManager
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(messageId.uuidString).m4a")
        guard FileManager.default.fileExists(atPath: audioURL.path) else { throw TranscriptionError.fileNotFound }

        // API key
        guard let apiKey = UserDefaults.standard.string(forKey: "groq_api_key"), !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        // Prepare multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendFormField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        func appendFileField(name: String, filename: String, mimeType: String, fileData: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Model and file
        appendFormField(name: "model", value: model)
        if let language = language, !language.isEmpty {
            appendFormField(name: "language", value: language)
        }
        if let audioData = try? Data(contentsOf: audioURL) {
            appendFileField(name: "file", filename: audioURL.lastPathComponent, mimeType: "audio/m4a", fileData: audioData)
        } else { throw TranscriptionError.fileNotFound }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let _ = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw TranscriptionError.invalidResponse
        }

        // Groq returns { text: "..." }
        let result = try JSONDecoder().decode(TranscriptionResult.self, from: data)
        return result.text
    }
}

