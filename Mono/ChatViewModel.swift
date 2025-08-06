import Foundation
import SwiftData

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
    @Published var isLoading = false
    @Published var currentMode: PersonalityMode = .smart
    var modelContext: ModelContext

    init(context: ModelContext) {
        self.modelContext = context
    }

    func sendMessage(_ input: String, handwritingMode: Bool = false) async {
        await MainActor.run {
            let userMessage = ChatMessage(text: input, isUser: true)
            modelContext.insert(userMessage)

            // Save the context to persist the user message
            try? modelContext.save()
        }

        await MainActor.run {
            isLoading = true
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
                modelContext.insert(botMessage)

                // Save the context to persist the bot message
                try? modelContext.save()
            }
        } catch {
            print("Mono error: \(error)")
            await MainActor.run {
                let errorMessage = ChatMessage(text: "[Error: Could not load reply]", isUser: false, isHandwritten: false)
                modelContext.insert(errorMessage)

                // Save the context to persist the error message
                try? modelContext.save()
            }
        }
        
        await MainActor.run {
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
            do {
                return try modelContext.fetch(FetchDescriptor<ChatMessage>())
                    .sorted(by: { $0.timestamp < $1.timestamp })
                    .suffix(10)
                    .map { msg in
                        ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
                    }
            } catch {
                print("Error fetching messages: \(error)")
                return []
            }
        }

        let systemPrompt: [[String: String]] = [
            ["role": "system", "content": currentMode.systemPrompt]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "llama3-70b-8192",
            "messages": systemPrompt + history + [["role": "user", "content": input]],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw NSError(domain: "MonoError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
        }
        
        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        return decoded.choices.first?.message.content ?? "..."
    }
    
    private func getAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: "groq_api_key")
    }
}
