//
//  MemoryPalaceManager.swift
//  Mono
//
//  Memory Palace Manager - Core Logic and AI Integration
//

import Foundation
import SwiftUI

@MainActor
class MemoryPalaceManager: ObservableObject {
    static let shared = MemoryPalaceManager()
    
    @Published var knowledgeGraph = KnowledgeGraph()
    @Published var searchIndex = SearchIndex()
    @Published var isProcessing = false
    @Published var lastError: String?
    
    private let aiServiceManager = AIServiceManager.shared
    
    private init() {
        loadMemoryPalace()
    }
    
    // MARK: - Memory Node Creation
    
    func processConversationForMemoryNodes(_ conversation: Conversation) async {
        guard !conversation.messages.isEmpty else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let insights = try await extractInsights(from: conversation)
            
            for insight in insights {
                let node = createMemoryNode(from: insight, conversation: conversation)
                addMemoryNode(node)
                
                // Find connections to existing nodes
                await findAndCreateConnections(for: node)
            }
            
            saveMemoryPalace()
        } catch {
            lastError = "Failed to process conversation: \(error.localizedDescription)"
        }
    }
    
    private func extractInsights(from conversation: Conversation) async throws -> [ConversationInsight] {
        let conversationText = conversation.messages.map { $0.text }.joined(separator: "\n")
        
        let prompt = """
        Analyze this conversation and extract key insights, facts, ideas, and important information that should be remembered. For each insight, provide:
        1. A clear title
        2. The main content/insight
        3. A brief summary
        4. 3-5 relevant keywords
        5. The type (insight, fact, idea, question, solution, pattern)
        6. Importance score (0.0-1.0)
        
        Conversation:
        \(conversationText.prefix(2000))
        
        Respond with JSON array:
        [{"title": "...", "content": "...", "summary": "...", "keywords": ["..."], "type": "insight", "importance": 0.8}]
        """
        
        let response = try await aiServiceManager.sendChatMessage(
            messages: [ChatMessage(text: prompt, isUser: true)],
            systemPrompt: "You are an expert at extracting and organizing knowledge from conversations. Extract meaningful insights that would be valuable to remember later.",
            temperature: 0.3
        )
        
        return parseInsightsFromResponse(response)
    }
    
    private func parseInsightsFromResponse(_ response: String) -> [ConversationInsight] {
        // Clean JSON response
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else { return [] }
        
        do {
            let insights = try JSONDecoder().decode([ConversationInsight].self, from: data)
            return insights
        } catch {
            print("Failed to parse insights: \(error)")
            return []
        }
    }
    
    private func createMemoryNode(from insight: ConversationInsight, conversation: Conversation) -> MemoryNode {
        let nodeType = MemoryNodeType(rawValue: insight.type) ?? .insight
        let messageIds = conversation.messages.map { $0.id }
        
        return MemoryNode(
            title: insight.title,
            content: insight.content,
            summary: insight.summary,
            keywords: insight.keywords,
            sourceConversationId: conversation.id,
            sourceMessageIds: messageIds,
            importance: insight.importance,
            nodeType: nodeType
        )
    }
    
    // MARK: - Connection Discovery
    
    private func findAndCreateConnections(for newNode: MemoryNode) async {
        let existingNodes = Array(knowledgeGraph.nodes.values)
        
        for existingNode in existingNodes {
            if let connection = await analyzeConnection(between: newNode, and: existingNode) {
                knowledgeGraph.addConnection(connection)
            }
        }
    }
    
    private func analyzeConnection(between node1: MemoryNode, and node2: MemoryNode) async -> KnowledgeConnection? {
        do {
            let prompt = """
            Analyze these two knowledge nodes and determine if there's a meaningful connection:
            
            Node 1: "\(node1.title)" - \(node1.summary)
            Node 2: "\(node2.title)" - \(node2.summary)
            
            If connected, respond with JSON:
            {"connected": true, "type": "similar|causal|contradictory|elaborative|temporal|thematic", "strength": 0.0-1.0, "description": "explanation"}
            
            If not connected:
            {"connected": false}
            """
            
            let response = try await aiServiceManager.sendChatMessage(
                messages: [ChatMessage(text: prompt, isUser: true)],
                systemPrompt: "You analyze relationships between knowledge concepts. Only identify meaningful, non-trivial connections.",
                temperature: 0.2
            )
            
            return parseConnectionFromResponse(response, sourceId: node1.id, targetId: node2.id)
        } catch {
            return nil
        }
    }
    
    private func parseConnectionFromResponse(_ response: String, sourceId: UUID, targetId: UUID) -> KnowledgeConnection? {
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let connected = json["connected"] as? Bool,
              connected,
              let typeString = json["type"] as? String,
              let type = ConnectionType(rawValue: typeString),
              let strength = json["strength"] as? Double,
              let description = json["description"] as? String else {
            return nil
        }
        
        return KnowledgeConnection(
            sourceNodeId: sourceId,
            targetNodeId: targetId,
            connectionType: type,
            strength: Float(strength),
            description: description
        )
    }
    
    // MARK: - Memory Palace Management
    
    func addMemoryNode(_ node: MemoryNode) {
        knowledgeGraph.addNode(node)
        searchIndex.indexNode(node)
    }
    
    func getMemoryNode(id: UUID) -> MemoryNode? {
        return knowledgeGraph.nodes[id]
    }
    
    func getAllMemoryNodes() -> [MemoryNode] {
        return Array(knowledgeGraph.nodes.values)
    }
    
    func getNodesByType(_ type: MemoryNodeType) -> [MemoryNode] {
        return knowledgeGraph.nodes.values.filter { $0.nodeType == type }
    }
    
    func getRecentNodes(limit: Int = 10) -> [MemoryNode] {
        return knowledgeGraph.timeline.suffix(limit)
            .compactMap { knowledgeGraph.nodes[$0] }
            .reversed()
    }
    
    func getTopicClusters() -> [String: [MemoryNode]] {
        var clusters: [String: [MemoryNode]] = [:]
        
        for (topic, nodeIds) in knowledgeGraph.topics {
            let nodes = nodeIds.compactMap { knowledgeGraph.nodes[$0] }
            if !nodes.isEmpty {
                clusters[topic] = nodes
            }
        }
        
        return clusters
    }
    
    // MARK: - Information Recall
    
    func recallInformation(for query: String) async -> [MemoryNode] {
        // Combine keyword search with AI-powered semantic search
        let keywordResults = knowledgeGraph.searchNodes(query: query)
        let semanticResults = await performSemanticSearch(query: query)
        
        // Merge and rank results
        let allResults = Set(keywordResults + semanticResults)
        return Array(allResults).sorted { node1, node2 in
            // Sort by relevance (importance + recency + access count)
            let score1 = node1.importance + Float(node1.accessCount) * 0.1 + (Date().timeIntervalSince(node1.createdAt) < 86400 ? 0.2 : 0.0)
            let score2 = node2.importance + Float(node2.accessCount) * 0.1 + (Date().timeIntervalSince(node2.createdAt) < 86400 ? 0.2 : 0.0)
            return score1 > score2
        }
    }
    
    private func performSemanticSearch(query: String) async -> [MemoryNode] {
        // For now, use TF-IDF scoring. In future, could use vector embeddings
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var nodeScores: [UUID: Float] = [:]
        
        for word in queryWords {
            for (nodeId, _) in searchIndex.termFrequency[word] ?? [:] {
                let score = searchIndex.calculateTFIDF(term: word, nodeId: nodeId)
                nodeScores[nodeId, default: 0] += score
            }
        }
        
        return nodeScores.sorted { $0.value > $1.value }
            .prefix(20)
            .compactMap { knowledgeGraph.nodes[$0.key] }
    }
    
    // MARK: - Persistence
    
    private func saveMemoryPalace() {
        // Save to UserDefaults for now, could move to Core Data later
        do {
            let graphData = try JSONEncoder().encode(knowledgeGraph)
            let indexData = try JSONEncoder().encode(searchIndex)
            
            UserDefaults.standard.set(graphData, forKey: "MemoryPalace_KnowledgeGraph")
            UserDefaults.standard.set(indexData, forKey: "MemoryPalace_SearchIndex")
        } catch {
            print("Failed to save memory palace: \(error)")
        }
    }
    
    private func loadMemoryPalace() {
        do {
            if let graphData = UserDefaults.standard.data(forKey: "MemoryPalace_KnowledgeGraph") {
                knowledgeGraph = try JSONDecoder().decode(KnowledgeGraph.self, from: graphData)
            }
            
            if let indexData = UserDefaults.standard.data(forKey: "MemoryPalace_SearchIndex") {
                searchIndex = try JSONDecoder().decode(SearchIndex.self, from: indexData)
            }
        } catch {
            print("Failed to load memory palace: \(error)")
        }
    }
}

// MARK: - Supporting Models

struct ConversationInsight: Codable {
    let title: String
    let content: String
    let summary: String
    let keywords: [String]
    let type: String
    let importance: Float
}
