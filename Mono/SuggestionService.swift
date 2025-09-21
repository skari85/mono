import Foundation

final class SuggestionService {
    static let shared = SuggestionService()
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    enum SuggestionError: Error { case missingAPIKey, invalidResponse }

    func suggest(query: String, topN: Int = 5, contextHints: String? = nil) async throws -> String {
        // Try to get API key from the current selected provider
        let aiServiceManager = AIServiceManager.shared
        
        // First try the current provider if it supports chat completion
        if let currentProvider = aiServiceManager.currentProvider,
           currentProvider.supportedCapabilities.contains(.chatCompletion),
           currentProvider.isConfigured {
            
            if currentProvider.id == "groq" {
                // Use Groq API directly for suggestions
                guard let apiKey = APIKeyManager.shared.getAPIKey(for: "groq") else {
                    throw SuggestionError.missingAPIKey
                }
                return try await makeGroqSuggestionRequest(apiKey: apiKey, query: query, topN: topN, contextHints: contextHints)
            }
        }
        
        // Fallback: try to find any configured provider that supports chat
        let configuredProviders = aiServiceManager.getConfiguredProviders()
        for provider in configuredProviders {
            if provider.supportedCapabilities.contains(.chatCompletion) && provider.id == "groq" {
                guard let apiKey = APIKeyManager.shared.getAPIKey(for: provider.id) else {
                    continue
                }
                return try await makeGroqSuggestionRequest(apiKey: apiKey, query: query, topN: topN, contextHints: contextHints)
            }
        }
        
        throw SuggestionError.missingAPIKey
    }
    
    private func makeGroqSuggestionRequest(apiKey: String, query: String, topN: Int, contextHints: String?) async throws -> String {

        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Get the selected model for Groq provider
        let aiServiceManager = AIServiceManager.shared
        let modelId = aiServiceManager.getSelectedModel(for: "groq")

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

