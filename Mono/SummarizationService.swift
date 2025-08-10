import Foundation

final class SummarizationService {
    static let shared = SummarizationService()
    private init() {}

    enum SummarizationError: Error {
        case missingAPIKey
        case invalidResponse
    }

    // Summarize free-form text using Groq Chat Completions (Llama)
    func summarize(text: String) async throws -> String {
        // API key
        guard let apiKey = UserDefaults.standard.string(forKey: "groq_api_key"), !apiKey.isEmpty else {
            throw SummarizationError.missingAPIKey
        }

        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let modelId = UserDefaults.standard.string(forKey: "llm_model") ?? "llama-3.1-8b-instant"

        let systemPrompt = """
        You are a focused summarization assistant. Given a raw transcript, produce a clear, concise Markdown summary with the following sections (only include a section if it has content):
        
        - Key Points: bullet list of the main ideas
        - Action Items: bullet list using imperative verbs, include owners/dates if present
        - Priorities: bullet list ordered from highest to lowest urgency/impact
        
        Rules:
        - Use short, scannable bullets (one line each if possible)
        - Avoid fluff, keep it practical
        - Preserve specific names, dates, numbers
        - If the input is messy or repetitive, consolidate cleanly
        """

        let body: [String: Any] = [
            "model": modelId,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SummarizationError.invalidResponse
        }

        struct CompletionResponse: Decodable {
            struct Choice: Decodable { struct Message: Decodable { let content: String } ; let message: Message }
            let choices: [Choice]
        }

        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

