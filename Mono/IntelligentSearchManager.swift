//
//  IntelligentSearchManager.swift
//  Mono
//
//  Intelligent Search System - Semantic Search and AI-Powered Context Understanding
//

import Foundation
import SwiftUI

@MainActor
class IntelligentSearchManager: ObservableObject {
    static let shared = IntelligentSearchManager()
    
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchHistory: [String] = []
    @Published var suggestedQueries: [String] = []
    @Published var lastError: String?
    
    private let aiServiceManager = AIServiceManager.shared
    private let memoryPalaceManager = MemoryPalaceManager.shared
    private var conversationIndex: ConversationSearchIndex = ConversationSearchIndex()
    
    private init() {
        loadSearchHistory()
        buildConversationIndex()
    }
    
    // MARK: - Main Search Interface
    
    func performIntelligentSearch(query: String, filters: SearchFilters = SearchFilters()) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        // Add to search history
        addToSearchHistory(query)

        // Perform multi-faceted search
        let conversationResults = await searchConversations(query: query, filters: filters)
        let memoryResults = await searchMemoryPalace(query: query, filters: filters)
        let semanticResults = await performSemanticSearch(query: query, filters: filters)

        // Combine and rank results
        let allResults = combineAndRankResults(
            conversationResults: conversationResults,
            memoryResults: memoryResults,
            semanticResults: semanticResults,
            query: query
        )

        searchResults = allResults

        // Generate suggested queries for next search
        suggestedQueries = await generateSuggestedQueries(basedOn: query, results: allResults)
    }
    
    // MARK: - Conversation Search
    
    private func searchConversations(query: String, filters: SearchFilters) async -> [SearchResult] {
        let dataManager = DataManager.shared
        let conversations = dataManager.conversations
        
        var results: [SearchResult] = []
        
        for conversation in conversations {
            // Apply date filters
            if let startDate = filters.startDate, conversation.createdAt < startDate { continue }
            if let endDate = filters.endDate, conversation.createdAt > endDate { continue }
            
            // Search within conversation messages
            for message in conversation.messages {
                let relevanceScore = calculateRelevanceScore(query: query, text: message.text)
                
                if relevanceScore > 0.1 { // Minimum relevance threshold
                    let result = SearchResult(
                        id: UUID(),
                        type: .conversation,
                        title: conversation.title,
                        content: message.text,
                        snippet: extractSnippet(from: message.text, query: query),
                        relevanceScore: relevanceScore,
                        sourceConversationId: conversation.id,
                        sourceMessageId: message.id,
                        timestamp: message.timestamp,
                        highlights: findHighlights(in: message.text, query: query)
                    )
                    results.append(result)
                }
            }
        }
        
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    // MARK: - Memory Palace Search
    
    private func searchMemoryPalace(query: String, filters: SearchFilters) async -> [SearchResult] {
        let memoryNodes = await memoryPalaceManager.recallInformation(for: query)
        
        return memoryNodes.compactMap { node in
            // Apply filters
            if let nodeTypes = filters.memoryNodeTypes, !nodeTypes.contains(node.nodeType) {
                return nil
            }
            
            let relevanceScore = calculateMemoryNodeRelevance(query: query, node: node)
            
            return SearchResult(
                id: UUID(),
                type: .memoryNode,
                title: node.title,
                content: node.content,
                snippet: node.summary,
                relevanceScore: relevanceScore,
                sourceConversationId: node.sourceConversationId,
                sourceMemoryNodeId: node.id,
                timestamp: node.createdAt,
                highlights: findHighlights(in: "\(node.title) \(node.content)", query: query),
                memoryNodeType: node.nodeType
            )
        }
    }
    
    // MARK: - Semantic Search with AI
    
    private func performSemanticSearch(query: String, filters: SearchFilters) async -> [SearchResult] {
        do {
            // Use AI to understand the semantic meaning of the query
            let expandedQuery = try await expandQuerySemantics(query)
            
            // Search using expanded semantic understanding
            let semanticResults = await searchWithSemanticUnderstanding(
                originalQuery: query,
                expandedQuery: expandedQuery,
                filters: filters
            )
            
            return semanticResults
        } catch {
            print("Semantic search failed: \(error)")
            return []
        }
    }
    
    private func expandQuerySemantics(_ query: String) async throws -> String {
        let prompt = """
        Analyze this search query and expand it with related concepts, synonyms, and semantic variations that would help find relevant information:
        
        Query: "\(query)"
        
        Provide related terms, concepts, and semantic variations that someone might use when discussing this topic. Include:
        - Synonyms and alternative phrasings
        - Related concepts and themes
        - Technical terms if applicable
        - Common ways people might express this idea
        
        Respond with a comma-separated list of terms and phrases.
        """
        
        let response = try await aiServiceManager.sendChatMessage(
            messages: [ChatMessage(text: prompt, isUser: true)],
            systemPrompt: "You are an expert at understanding semantic relationships and expanding search queries to find relevant information.",
            temperature: 0.3
        )
        
        return response
    }
    
    private func searchWithSemanticUnderstanding(originalQuery: String, expandedQuery: String, filters: SearchFilters) async -> [SearchResult] {
        let allTerms = (originalQuery + " " + expandedQuery)
            .components(separatedBy: .punctuationCharacters)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        var results: [SearchResult] = []
        let dataManager = DataManager.shared
        
        for conversation in dataManager.conversations {
            for message in conversation.messages {
                let semanticScore = calculateSemanticRelevance(
                    text: message.text,
                    originalQuery: originalQuery,
                    expandedTerms: allTerms
                )
                
                if semanticScore > 0.15 {
                    let result = SearchResult(
                        id: UUID(),
                        type: .semanticMatch,
                        title: "Semantic match in \(conversation.title)",
                        content: message.text,
                        snippet: extractSnippet(from: message.text, query: originalQuery),
                        relevanceScore: semanticScore,
                        sourceConversationId: conversation.id,
                        sourceMessageId: message.id,
                        timestamp: message.timestamp,
                        highlights: findHighlights(in: message.text, query: originalQuery)
                    )
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Result Ranking and Combination
    
    private func combineAndRankResults(
        conversationResults: [SearchResult],
        memoryResults: [SearchResult],
        semanticResults: [SearchResult],
        query: String
    ) -> [SearchResult] {
        
        var allResults = conversationResults + memoryResults + semanticResults
        
        // Remove duplicates based on content similarity
        allResults = removeDuplicateResults(allResults)
        
        // Apply advanced ranking algorithm
        allResults = allResults.map { result in
            var updatedResult = result
            updatedResult.relevanceScore = calculateFinalRelevanceScore(result: result, query: query)
            return updatedResult
        }
        
        // Sort by final relevance score
        return allResults.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func calculateFinalRelevanceScore(result: SearchResult, query: String) -> Float {
        var score = result.relevanceScore
        
        // Boost recent results
        let daysSinceCreation = Date().timeIntervalSince(result.timestamp) / 86400
        let recencyBoost = max(0, 1.0 - Float(daysSinceCreation) / 30.0) * 0.2
        score += recencyBoost
        
        // Boost memory palace results (they're curated insights)
        if result.type == .memoryNode {
            score += 0.3
        }
        
        // Boost exact matches in title
        if result.title.lowercased().contains(query.lowercased()) {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    // MARK: - Helper Functions
    
    private func calculateRelevanceScore(query: String, text: String) -> Float {
        let queryTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let textLower = text.lowercased()
        
        var score: Float = 0.0
        var matchedTerms = 0
        
        for term in queryTerms {
            if textLower.contains(term) {
                matchedTerms += 1
                // Boost for exact phrase matches
                if textLower.contains(query.lowercased()) {
                    score += 0.5
                } else {
                    score += 0.2
                }
            }
        }
        
        // Normalize by query length
        if !queryTerms.isEmpty {
            score *= Float(matchedTerms) / Float(queryTerms.count)
        }
        
        return min(score, 1.0)
    }
    
    private func calculateMemoryNodeRelevance(query: String, node: MemoryNode) -> Float {
        let titleScore = calculateRelevanceScore(query: query, text: node.title) * 1.5
        let contentScore = calculateRelevanceScore(query: query, text: node.content)
        let keywordScore = node.keywords.contains { $0.lowercased().contains(query.lowercased()) } ? 0.3 : 0.0
        
        let importanceScore = Float(node.importance) * 0.2
        let totalScore = titleScore + contentScore + Float(keywordScore) + importanceScore
        return min(totalScore, 1.0)
    }
    
    private func calculateSemanticRelevance(text: String, originalQuery: String, expandedTerms: [String]) -> Float {
        let textLower = text.lowercased()
        var score: Float = 0.0
        var matchCount = 0
        
        // Check original query (higher weight)
        if textLower.contains(originalQuery.lowercased()) {
            score += 0.6
            matchCount += 1
        }
        
        // Check expanded terms (lower weight)
        for term in expandedTerms {
            if textLower.contains(term.lowercased()) {
                score += 0.1
                matchCount += 1
            }
        }
        
        // Normalize by number of potential matches
        if !expandedTerms.isEmpty {
            score *= Float(matchCount) / Float(expandedTerms.count + 1)
        }
        
        return min(score, 1.0)
    }
    
    private func extractSnippet(from text: String, query: String) -> String {
        let queryLower = query.lowercased()
        let textLower = text.lowercased()
        
        if let range = textLower.range(of: queryLower) {
            let start = max(text.startIndex, text.index(range.lowerBound, offsetBy: -50, limitedBy: text.startIndex) ?? text.startIndex)
            let end = min(text.endIndex, text.index(range.upperBound, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex)
            
            var snippet = String(text[start..<end])
            if start != text.startIndex { snippet = "..." + snippet }
            if end != text.endIndex { snippet = snippet + "..." }
            
            return snippet
        }
        
        return String(text.prefix(100)) + (text.count > 100 ? "..." : "")
    }
    
    private func findHighlights(in text: String, query: String) -> [String] {
        let queryTerms = query.components(separatedBy: .whitespacesAndNewlines)
        return queryTerms.filter { !$0.isEmpty && text.lowercased().contains($0.lowercased()) }
    }
    
    private func removeDuplicateResults(_ results: [SearchResult]) -> [SearchResult] {
        var seen = Set<String>()
        return results.filter { result in
            let key = "\(result.sourceConversationId)_\(result.sourceMessageId?.uuidString ?? "")"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
    
    // MARK: - Search History and Suggestions
    
    private func addToSearchHistory(_ query: String) {
        searchHistory.removeAll { $0 == query }
        searchHistory.insert(query, at: 0)
        searchHistory = Array(searchHistory.prefix(20))
        saveSearchHistory()
    }
    
    private func generateSuggestedQueries(basedOn query: String, results: [SearchResult]) async -> [String] {
        // Generate suggestions based on search results and common patterns
        var suggestions: [String] = []
        
        // Add related topics from memory palace
        let relatedTopics = results.compactMap { $0.memoryNodeType?.rawValue }.unique()
        suggestions.append(contentsOf: relatedTopics.map { "Show me all \($0)s" })
        
        // Add time-based suggestions
        suggestions.append("Recent discussions about \(query)")
        suggestions.append("Earlier conversations about \(query)")
        
        return Array(suggestions.prefix(5))
    }
    
    // MARK: - Persistence
    
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "IntelligentSearch_History")
    }
    
    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "IntelligentSearch_History") ?? []
    }
    
    private func buildConversationIndex() {
        // Build search index for faster lookups
        let dataManager = DataManager.shared
        conversationIndex = ConversationSearchIndex()
        
        for conversation in dataManager.conversations {
            conversationIndex.indexConversation(conversation)
        }
    }
}

// MARK: - Supporting Models

struct SearchResult: Identifiable {
    let id: UUID
    let type: SearchResultType
    let title: String
    let content: String
    let snippet: String
    var relevanceScore: Float
    let sourceConversationId: UUID
    let sourceMessageId: UUID?
    let sourceMemoryNodeId: UUID?
    let timestamp: Date
    let highlights: [String]
    let memoryNodeType: MemoryNodeType?
    
    init(id: UUID, type: SearchResultType, title: String, content: String, snippet: String, 
         relevanceScore: Float, sourceConversationId: UUID, sourceMessageId: UUID? = nil, 
         sourceMemoryNodeId: UUID? = nil, timestamp: Date, highlights: [String], 
         memoryNodeType: MemoryNodeType? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.sourceConversationId = sourceConversationId
        self.sourceMessageId = sourceMessageId
        self.sourceMemoryNodeId = sourceMemoryNodeId
        self.timestamp = timestamp
        self.highlights = highlights
        self.memoryNodeType = memoryNodeType
    }
}

enum SearchResultType {
    case conversation
    case memoryNode
    case semanticMatch
}

struct SearchFilters {
    var startDate: Date?
    var endDate: Date?
    var memoryNodeTypes: [MemoryNodeType]?
    var conversationIds: [UUID]?
    var minRelevanceScore: Float = 0.1
}

struct ConversationSearchIndex {
    private var wordToConversations: [String: Set<UUID>] = [:]
    
    mutating func indexConversation(_ conversation: Conversation) {
        let allText = conversation.messages.map { $0.text }.joined(separator: " ")
        let words = allText.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        for word in words {
            wordToConversations[word, default: Set()].insert(conversation.id)
        }
    }
    
    func findConversations(containing words: [String]) -> Set<UUID> {
        guard !words.isEmpty else { return Set() }
        
        var result = wordToConversations[words[0].lowercased()] ?? Set()
        
        for word in words.dropFirst() {
            let wordConversations = wordToConversations[word.lowercased()] ?? Set()
            result = result.intersection(wordConversations)
        }
        
        return result
    }
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}
