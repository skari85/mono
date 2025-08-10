import Foundation

final class SummarizationService {
    static let shared = SummarizationService()
    private init() {}

    enum SummarizationError: Error {
        case missingAPIKey
        case invalidResponse
        case invalidJSON
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

    // MARK: - Structured "color‑coded sheets" summary
    // Returns a strongly-typed structure with tags, action items, and key insights.
    func summarizeStructured(text: String) async throws -> StructuredSummary {
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
        You are a meeting notes structurer. Extract:
        - key_points (array of short bullet strings)
        - action_items (array of imperative bullet strings; include owner/date if present)
        - key_insights (array of insights/observations)
        - tags (array of 3-7 short lowercase slugs)

        Respond with ONLY minified JSON that conforms to this schema:
        {"key_points":[],"action_items":[],"key_insights":[],"tags":[]}
        No prose, no markdown, no code fences.
        """

        let body: [String: Any] = [
            "model": modelId,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.2
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
        let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "{}"

        // Some models return JSON in code fences. Strip if present.
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else { throw SummarizationError.invalidJSON }
        do {
            return try JSONDecoder().decode(StructuredSummary.self, from: jsonData)
        } catch {
            throw SummarizationError.invalidJSON
        }
    }
}
