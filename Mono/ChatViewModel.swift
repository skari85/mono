import Foundation

enum PersonalityMode: String, CaseIterable {
    case smart = "🧠 Smart"
    case quiet = "🤫 Quiet"
    case play = "🎭 Play"

    var systemPrompt: String {
        switch self {
        case .smart:
            return "You are Mono, a helpful and charming AI assistant. Be direct, practical, and warm. Focus on being genuinely useful while maintaining a friendly, approachable tone. Keep responses clear and actionable."
        case .quiet:
            return "You are Mono, a helpful and charming AI assistant. Be concise, direct, and calm. Give brief, practical answers with a gentle, understated warmth."
        case .play:
            return "You are Mono, a helpful and charming AI assistant. Be practical but add light humor and creativity. Stay useful and direct while being engaging and fun."
        }
    }
}

class ChatViewModel: ObservableObject {
    enum LoadingPhase { case none, transcribing, thinking }

    @Published var isLoading = false
    @Published var loadingPhase: LoadingPhase = .none
    @Published var currentMode: PersonalityMode = .smart
    private let dataManager: DataManager
    @Published var lastError: String? = nil
    @Published var lastPrompt: String? = nil

    func retryLast() async {
        guard let prompt = lastPrompt else { return }
        await sendMessage(prompt)
    }



    var loadingLabel: String {
        switch loadingPhase {
        case .transcribing: return "Transcribing..."
        case .thinking: return "Thinking..."
        case .none: return ""
        }
    }

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    func sendVoiceMessage(_ voiceMessage: ChatMessage) async {
        await MainActor.run {
            isLoading = true
            loadingPhase = .transcribing
        }
        do {
            // 1) Transcribe user audio with Groq Whisper
            let lang = UserDefaults.standard.string(forKey: "transcription_language")
            let language = (lang == nil || lang == "auto") ? nil : lang
            let whisperModel = UserDefaults.standard.string(forKey: "whisper_model") ?? "whisper-large-v3-turbo"
            let messageId = voiceMessage.recordingId ?? voiceMessage.id
            let transcription = try await TranscriptionService.shared.transcribeGroqWhisper(messageId: messageId, model: whisperModel, language: language)

            // 2) Update the original user message with transcribed text
            await MainActor.run {
                voiceMessage.text = transcription
                loadingPhase = .thinking
            }

            // 3) Ask LLM for a reply using recent history
            let response = try await fetchMonoResponse(for: transcription)

            await MainActor.run {
                let aiMessage = ChatMessage(text: response, isUser: false)
                dataManager.addChatMessage(aiMessage)
                loadingPhase = .none
                isLoading = false
            }
        } catch {
            print("Transcription/LLM error: \(error)")
            await MainActor.run {
                let errorMessage = ChatMessage(text: "[Transcription failed. Please try again.]", isUser: false)
                dataManager.addChatMessage(errorMessage)
                lastError = "Transcription or LLM error. Check API key and model."
                loadingPhase = .none
                isLoading = false
            }
        }
    }

    func sendMessage(_ input: String, handwritingMode: Bool = false) async {
        await MainActor.run {
            let userMessage = ChatMessage(text: input, isUser: true)
            dataManager.addChatMessage(userMessage)
            lastPrompt = input
        }

        await MainActor.run {
            isLoading = true
            loadingPhase = .thinking
        }

        do {
            let reply = try await fetchMonoResponse(for: input)
            let clean = reply.trimmingCharacters(in: .whitespacesAndNewlines)

            await MainActor.run {
                let botMessage = ChatMessage(
                    text: clean.isEmpty ? "[No response]" : clean,
                    isUser: false,
                    isHandwritten: handwritingMode,
                    handwritingStyle: handwritingMode ? HandwritingStyle.allCases.randomElement() ?? .casual : .casual
                )
                dataManager.addChatMessage(botMessage)
            }
        } catch {
            print("Mono error: \(error)")
            await MainActor.run {
                let errorMessage = ChatMessage(text: "[Error: Could not load reply]", isUser: false, isHandwritten: false)
                dataManager.addChatMessage(errorMessage)
                lastError = "Chat API error. See console for details."
            }
        }

        await MainActor.run {
            loadingPhase = .none
            isLoading = false
        }
    }

    private func fetchMonoResponse(for input: String) async throws -> String {
        // Check if API key is set
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            throw NSError(domain: "MonoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please set your Groq API key in Settings"])
        }

        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

        let history = await MainActor.run {
            return dataManager.chatMessages
                .sorted(by: { $0.timestamp < $1.timestamp })
                .suffix(10)
                .map { msg in
                    ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
                }
        }

        let systemPrompt: [[String: String]] = [
            ["role": "system", "content": currentMode.systemPrompt]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let modelId = UserDefaults.standard.string(forKey: "llm_model") ?? "llama-3.1-8b-instant"
        let body: [String: Any] = [
            "model": modelId,
            "messages": systemPrompt + history + [["role": "user", "content": input]],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            print("Groq error status: \(httpResponse.statusCode) body: \(bodyText)")
            throw NSError(domain: "MonoError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed (\(httpResponse.statusCode))"])
        }

        do {
            let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
            if let content = decoded.choices.first?.message.content, !content.isEmpty {
                return content
            }
        } catch {
            let text = String(data: data, encoding: .utf8) ?? ""
            print("Groq decode error: \(error) raw: \(text)")
        }
        return "..."
    }

    private func getAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: "groq_api_key")
    }
}
