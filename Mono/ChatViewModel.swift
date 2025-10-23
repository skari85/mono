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

            // 2) Update the original user message with transcribed text AND refresh data manager
            await MainActor.run {
                voiceMessage.text = transcription
                // Force a refresh by updating the data manager's messages array
                if let index = dataManager.chatMessages.firstIndex(where: { $0.id == voiceMessage.id }) {
                    dataManager.chatMessages[index].text = transcription
                }
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

                // Provide user-friendly error messages
                if let aiError = error as? AIServiceError {
                    lastError = aiError.localizedDescription
                } else {
                    lastError = "Transcription failed. Please check your connection and try again."
                }

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

                // Provide user-friendly error messages
                if let aiError = error as? AIServiceError {
                    lastError = aiError.localizedDescription
                } else {
                    lastError = "Chat API error. Please check your connection and try again."
                }
            }
        }

        await MainActor.run {
            loadingPhase = .none
            isLoading = false
        }
    }

    private func fetchMonoResponse(for input: String) async throws -> String {
        let history = await MainActor.run {
            return dataManager.chatMessages
                .sorted(by: { $0.timestamp < $1.timestamp })
                .suffix(10)
        }

        // Enhance system prompt with calendar context if available
        let enhancedSystemPrompt = await buildEnhancedSystemPrompt(basePrompt: currentMode.systemPrompt, userInput: input)

        return try await AIServiceManager.shared.sendChatMessage(
            messages: Array(history),
            systemPrompt: enhancedSystemPrompt,
            temperature: 0.7
        )
    }
    
    private func buildEnhancedSystemPrompt(basePrompt: String, userInput: String) async -> String {
        var enhancedPrompt = basePrompt
        
        // Add calendar context if user is asking about calendar-related topics
        let calendarKeywords = ["calendar", "schedule", "event", "meeting", "appointment", "today", "tomorrow", "next week", "time", "when"]
        let isCalendarRelated = calendarKeywords.contains { userInput.lowercased().contains($0) }
        
        if isCalendarRelated && CalendarManager.shared.hasCalendarAccess {
            let calendarSummary = CalendarManager.shared.generateCalendarSummaryForAI()
            enhancedPrompt += "\n\nCalendar Context:\n\(calendarSummary)"
        }
        
        return enhancedPrompt
    }
}
