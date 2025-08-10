import Foundation

final class SuggestionService {
    static let shared = SuggestionService()
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    enum SuggestionError: Error { case missingAPIKey, invalidResponse }

    func suggest(query: String, topN: Int = 5, contextHints: String? = nil) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "groq_api_key"), !apiKey.isEmpty else {
            throw SuggestionError.missingAPIKey
        }

        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let modelId = UserDefaults.standard.string(forKey: "llm_model") ?? "llama-3.1-8b-instant"

        let systemPrompt = """
        You are a practical recommendation engine. Given a user query, produce a concise list of the top items with short reasons based on widely known facts. If you are not confident, say so.

        Output format in Markdown:
        - A title line summarizing what you are ranking
        - A ranked list of exactly TOP_N items with this format per item:
          1. Name — one-sentence reason highlighting what makes it strong; include a key attribute (e.g., vibe, crowd level, views, amenities)
        - A brief closing tip (one sentence)

        Rules:
        - Be specific and concrete; avoid hype
        - Do not invent precise stats; if a detail is uncertain, use cautious phrasing
        - No fictional places; if insufficient info, respond with an honest limitation
        """

        var userPrompt = """
        Query: \(query)
        TOP_N: \(max(1, min(10, topN)))
        """
        if let hints = contextHints, !hints.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userPrompt += "\nContext hints (recent chat):\n\(hints)"
        }

        let body: [String: Any] = [
            "model": modelId,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.5
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SuggestionError.invalidResponse
        }

        struct CompletionResponse: Decodable { struct Choice: Decodable { struct Message: Decodable { let content: String } ; let message: Message } ; let choices: [Choice] }
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

