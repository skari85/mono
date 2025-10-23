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
            
            // Check if this was a calendar-related request and actually create the event
            await handleCalendarIntentIfNeeded(userInput: input, aiResponse: clean)
            
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
        let calendarKeywords = ["calendar", "schedule", "event", "meeting", "appointment", "today", "tomorrow", "next week", "time", "when", "add to", "create"]
        let isCalendarRelated = calendarKeywords.contains { userInput.lowercased().contains($0) }
        
        if isCalendarRelated && CalendarManager.shared.hasCalendarAccess {
            let calendarSummary = CalendarManager.shared.generateCalendarSummaryForAI()
            enhancedPrompt += "\n\nCalendar Context:\n\(calendarSummary)"
            enhancedPrompt += "\n\nIMPORTANT: When the user asks to add something to their calendar, respond with 'I'll add that to your calendar' and include the event details in your response. The app will automatically create the calendar event."
        }
        
        return enhancedPrompt
    }
    
    // MARK: - Calendar Intent Detection and Execution
    
    private func handleCalendarIntentIfNeeded(userInput: String, aiResponse: String) async {
        // Check if this looks like a calendar creation request
        let addKeywords = ["add to calendar", "add to my calendar", "create event", "schedule", "add that to", "put that in", "save to calendar"]
        let hasAddIntent = addKeywords.contains { userInput.lowercased().contains($0) } ||
                          addKeywords.contains { aiResponse.lowercased().contains($0) }
        
        guard hasAddIntent && CalendarManager.shared.hasCalendarAccess else { return }
        
        // Extract event details from the user's request
        let eventDetails = await extractEventDetails(from: userInput, aiContext: aiResponse)
        
        guard let details = eventDetails else { return }
        
        // Actually create the calendar event
        let success = await createCalendarEvent(details: details)
        
        if success {
            await MainActor.run {
                let confirmMessage = ChatMessage(
                    text: "✅ Calendar event created: \"\(details.title)\" on \(formatDate(details.date))",
                    isUser: false
                )
                dataManager.addChatMessage(confirmMessage)
            }
            print("✅ Calendar event created successfully: \(details.title)")
        } else {
            await MainActor.run {
                let errorMessage = ChatMessage(
                    text: "❌ I couldn't create the calendar event. Please make sure I have calendar access in Settings.",
                    isUser: false
                )
                dataManager.addChatMessage(errorMessage)
            }
            print("❌ Failed to create calendar event")
        }
    }
    
    private func extractEventDetails(from userInput: String, aiContext: String) async -> EventDetails? {
        // Simple parsing without AI - more reliable and faster
        let input = userInput.lowercased()
        
        // Extract title - everything before date/time keywords
        let dateKeywords = ["tomorrow", "today", "next", "on monday", "on tuesday", "on wednesday", "on thursday", "on friday", "on saturday", "on sunday", "at", "pm", "am"]
        var title = userInput
        for keyword in dateKeywords {
            if let range = input.range(of: keyword) {
                title = String(userInput[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Clean up title - remove calendar-related words
        title = title.replacingOccurrences(of: "add to calendar", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "add to my calendar", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "schedule", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "create event", with: "", options: .caseInsensitive)
        title = title.trimmingCharacters(in: .whitespaces)
        
        if title.isEmpty {
            title = "New Event"
        }
        
        // Parse date
        var eventDate = Date()
        let calendar = Calendar.current
        
        if input.contains("tomorrow") {
            eventDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        } else if input.contains("next monday") {
            eventDate = getNextWeekday(.monday) ?? Date()
        } else if input.contains("next tuesday") {
            eventDate = getNextWeekday(.tuesday) ?? Date()
        } else if input.contains("next wednesday") {
            eventDate = getNextWeekday(.wednesday) ?? Date()
        } else if input.contains("next thursday") {
            eventDate = getNextWeekday(.thursday) ?? Date()
        } else if input.contains("next friday") {
            eventDate = getNextWeekday(.friday) ?? Date()
        } else if input.contains("next saturday") {
            eventDate = getNextWeekday(.saturday) ?? Date()
        } else if input.contains("next sunday") {
            eventDate = getNextWeekday(.sunday) ?? Date()
        }
        
        // Parse time
        var hour = 10 // default 10 AM
        var minute = 0
        
        // Look for time patterns like "2pm", "2:30pm", "14:00"
        let timePattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        if let regex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) {
            
            if let hourRange = Range(match.range(at: 1), in: input) {
                hour = Int(input[hourRange]) ?? 10
            }
            if match.range(at: 2).location != NSNotFound,
               let minuteRange = Range(match.range(at: 2), in: input) {
                minute = Int(input[minuteRange]) ?? 0
            }
            if match.range(at: 3).location != NSNotFound,
               let ampmRange = Range(match.range(at: 3), in: input) {
                let ampm = String(input[ampmRange]).lowercased()
                if ampm == "pm" && hour < 12 {
                    hour += 12
                } else if ampm == "am" && hour == 12 {
                    hour = 0
                }
            }
        }
        
        // Set time on date
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        dateComponents.hour = hour
        dateComponents.minute = minute
        eventDate = calendar.date(from: dateComponents) ?? eventDate
        
        // Duration (default 1 hour)
        let duration: TimeInterval = 3600
        
        print("✅ Parsed calendar event: \(title) at \(eventDate)")
        
        return EventDetails(
            title: title,
            date: eventDate,
            duration: duration,
            notes: nil
        )
    }
    
    private func getNextWeekday(_ weekday: Calendar.Component) -> Date? {
        // This is a simplified version - you'd need to implement proper weekday finding
        let calendar = Calendar.current
        let today = Date()
        
        // Map component to weekday number (1 = Sunday, 7 = Saturday)
        let targetWeekday: Int
        switch weekday {
        case .sunday: targetWeekday = 1
        case .monday: targetWeekday = 2
        case .tuesday: targetWeekday = 3
        case .wednesday: targetWeekday = 4
        case .thursday: targetWeekday = 5
        case .friday: targetWeekday = 6
        case .saturday: targetWeekday = 7
        default: return nil
        }
        
        let currentWeekday = calendar.component(.weekday, from: today)
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7 // Next week
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)
    }
    
    private func createCalendarEvent(details: EventDetails) async -> Bool {
        guard CalendarManager.shared.hasCalendarAccess else {
            print("❌ No calendar access")
            return false
        }
        
        let event = await CalendarManager.shared.createEvent(
            title: details.title,
            startDate: details.date,
            duration: details.duration,
            notes: details.notes
        )
        
        return event != nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct EventDetails {
    let title: String
    let date: Date
    let duration: TimeInterval
    let notes: String?
}
