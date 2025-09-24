//
//  MemoryPalace.swift
//  Mono
//
//  Memory Palace System - Core Data Models and Logic
//

import Foundation
import SwiftUI

// MARK: - Memory Node System

struct MemoryNode: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let content: String
    let summary: String
    let keywords: [String]
    let sourceConversationId: UUID
    let sourceMessageIds: [UUID]
    let createdAt: Date
    let lastAccessedAt: Date
    let accessCount: Int
    let importance: Float // 0.0 - 1.0
    let nodeType: MemoryNodeType
    let connections: [UUID] // Connected memory node IDs
    let embedding: [Float]? // Vector embedding for semantic search
    
    init(title: String, content: String, summary: String, keywords: [String], 
         sourceConversationId: UUID, sourceMessageIds: [UUID], 
         importance: Float = 0.5, nodeType: MemoryNodeType = .insight) {
        self.title = title
        self.content = content
        self.summary = summary
        self.keywords = keywords
        self.sourceConversationId = sourceConversationId
        self.sourceMessageIds = sourceMessageIds
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.accessCount = 0
        self.importance = importance
        self.nodeType = nodeType
        self.connections = []
        self.embedding = nil
    }
}

enum MemoryNodeType: String, CaseIterable, Codable {
    case insight = "insight"
    case fact = "fact"
    case idea = "idea"
    case question = "question"
    case solution = "solution"
    case pattern = "pattern"
    case connection = "connection"
    
    var icon: String {
        switch self {
        case .insight: return "lightbulb.fill"
        case .fact: return "info.circle.fill"
        case .idea: return "brain.head.profile"
        case .question: return "questionmark.circle.fill"
        case .solution: return "checkmark.seal.fill"
        case .pattern: return "arrow.triangle.2.circlepath"
        case .connection: return "link.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .insight: return .yellow
        case .fact: return .blue
        case .idea: return .purple
        case .question: return .orange
        case .solution: return .green
        case .pattern: return .indigo
        case .connection: return .pink
        }
    }
}

// MARK: - Knowledge Graph

struct KnowledgeGraph: Codable {
    var nodes: [UUID: MemoryNode] = [:]
    var connections: [KnowledgeConnection] = []
    var topics: [String: [UUID]] = [:] // Topic -> Node IDs
    var timeline: [UUID] = [] // Chronological order of nodes
    
    mutating func addNode(_ node: MemoryNode) {
        nodes[node.id] = node
        timeline.append(node.id)
        
        // Index by keywords/topics
        for keyword in node.keywords {
            if topics[keyword] == nil {
                topics[keyword] = []
            }
            topics[keyword]?.append(node.id)
        }
    }
    
    mutating func addConnection(_ connection: KnowledgeConnection) {
        connections.append(connection)
        
        // Update node connections
        if let sourceNode = nodes[connection.sourceNodeId] {
            var updatedConnections = sourceNode.connections
            if !updatedConnections.contains(connection.targetNodeId) {
                updatedConnections.append(connection.targetNodeId)
            }
            let updatedNode = MemoryNode(
                title: sourceNode.title,
                content: sourceNode.content,
                summary: sourceNode.summary,
                keywords: sourceNode.keywords,
                sourceConversationId: sourceNode.sourceConversationId,
                sourceMessageIds: sourceNode.sourceMessageIds,
                importance: sourceNode.importance,
                nodeType: sourceNode.nodeType
            )
            nodes[connection.sourceNodeId] = updatedNode
        }
    }
    
    func getConnectedNodes(for nodeId: UUID) -> [MemoryNode] {
        guard let node = nodes[nodeId] else { return [] }
        return node.connections.compactMap { nodes[$0] }
    }
    
    func getNodesByTopic(_ topic: String) -> [MemoryNode] {
        guard let nodeIds = topics[topic] else { return [] }
        return nodeIds.compactMap { nodes[$0] }
    }
    
    func searchNodes(query: String) -> [MemoryNode] {
        let lowercaseQuery = query.lowercased()
        return nodes.values.filter { node in
            node.title.lowercased().contains(lowercaseQuery) ||
            node.content.lowercased().contains(lowercaseQuery) ||
            node.summary.lowercased().contains(lowercaseQuery) ||
            node.keywords.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
}

struct KnowledgeConnection: Identifiable, Codable {
    var id = UUID()
    let sourceNodeId: UUID
    let targetNodeId: UUID
    let connectionType: ConnectionType
    let strength: Float // 0.0 - 1.0
    let description: String
    let createdAt: Date
    
    init(sourceNodeId: UUID, targetNodeId: UUID, connectionType: ConnectionType, 
         strength: Float, description: String) {
        self.sourceNodeId = sourceNodeId
        self.targetNodeId = targetNodeId
        self.connectionType = connectionType
        self.strength = strength
        self.description = description
        self.createdAt = Date()
    }
}

enum ConnectionType: String, CaseIterable, Codable {
    case similar = "similar"
    case causal = "causal"
    case contradictory = "contradictory"
    case elaborative = "elaborative"
    case temporal = "temporal"
    case thematic = "thematic"
    
    var description: String {
        switch self {
        case .similar: return "Similar concepts"
        case .causal: return "Cause and effect"
        case .contradictory: return "Opposing views"
        case .elaborative: return "Builds upon"
        case .temporal: return "Time-related"
        case .thematic: return "Same theme"
        }
    }
}

// MARK: - Search Index

struct SearchIndex: Codable {
    var termFrequency: [String: [UUID: Int]] = [:] // Term -> NodeID -> Frequency
    var documentFrequency: [String: Int] = [:] // Term -> Document count
    var nodeWordCounts: [UUID: Int] = [:] // NodeID -> Total words
    var totalDocuments: Int = 0
    
    mutating func indexNode(_ node: MemoryNode) {
        let words = extractWords(from: "\(node.title) \(node.content) \(node.summary)")
        nodeWordCounts[node.id] = words.count
        totalDocuments += 1
        
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
        
        for (word, count) in wordCounts {
            if termFrequency[word] == nil {
                termFrequency[word] = [:]
                documentFrequency[word] = 0
            }
            
            if termFrequency[word]![node.id] == nil {
                documentFrequency[word]! += 1
            }
            
            termFrequency[word]![node.id] = count
        }
    }
    
    func calculateTFIDF(term: String, nodeId: UUID) -> Float {
        guard let tf = termFrequency[term]?[nodeId],
              let df = documentFrequency[term],
              let wordCount = nodeWordCounts[nodeId],
              df > 0, totalDocuments > 0 else { return 0.0 }
        
        let termFreq = Float(tf) / Float(wordCount)
        let inverseDocFreq = log(Float(totalDocuments) / Float(df))
        
        return termFreq * inverseDocFreq
    }
    
    private func extractWords(from text: String) -> [String] {
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
            .components(separatedBy: .punctuationCharacters)
            .filter { !$0.isEmpty && $0.count > 2 }
    }
}
