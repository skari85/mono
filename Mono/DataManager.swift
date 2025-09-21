//
//  DataManager.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation
import SwiftUI

// MARK: - Smart Cross-Reference Models

struct IntelligentReference: Identifiable, Codable {
    var id = UUID()
    let sourceConversationId: UUID
    let relevantQuote: String
    let contextSummary: String
    let confidenceScore: Float
    let connectionType: String
    let createdAt: Date
    
    init(sourceConversationId: UUID, relevantQuote: String, contextSummary: String, confidenceScore: Float, connectionType: String) {
        self.sourceConversationId = sourceConversationId
        self.relevantQuote = relevantQuote
        self.contextSummary = contextSummary
        self.confidenceScore = confidenceScore
        self.connectionType = connectionType
        self.createdAt = Date()
    }
}

struct ConversationInsight: Identifiable, Codable {
    var id = UUID()
    let conversationId: UUID
    let insightType: InsightType
    let title: String
    let description: String
    let actionable: Bool
    let priority: Int
    let createdAt: Date
    
    enum InsightType: String, Codable, CaseIterable {
        case pattern = "pattern"
        case decision = "decision"
        case followUp = "follow_up"
        case connection = "connection"
        case trend = "trend"
    }
}

// MARK: - Simple In-Memory Data Manager
class DataManager: ObservableObject {
    static let shared = DataManager()

    // In-memory storage
    @Published var chatMessages: [ChatMessage] = [] // reflects the currently open conversation
    @Published var thoughts: [Thought] = []

    @Published var tasks: [TaskItem] = []

    // Conversations
    @Published var conversations: [Conversation] = []
    @Published var selectedConversationId: UUID? = nil
    
    // Smart Cross-References
    @Published var intelligentReferences: [IntelligentReference] = []
    @Published var conversationInsights: [ConversationInsight] = []

    private init() {
        print("🔧 DataManager initialized")
        load()
        if chatMessages.isEmpty && conversations.isEmpty {
            createSampleData()
            save()
        }

        // Ensure current messages are in a conversation
        if !chatMessages.isEmpty && selectedConversationId == nil {
            // Create a conversation for existing messages
            let conversation = Conversation(title: "Welcome Chat", messages: chatMessages)
            conversations.append(conversation)
            selectedConversationId = conversation.id
            save()
            print("🔄 Created conversation for existing messages")
        }
    }

    // MARK: - Chat Message Management
    func addChatMessage(_ message: ChatMessage) {
        chatMessages.append(message)
        // Also reflect in selected conversation (if any)
        if let sel = selectedConversationId, let idx = conversations.firstIndex(where: { $0.id == sel }) {
            conversations[idx].messages = chatMessages
        }
        save()
        print("💬 Added chat message: \(message.text)")
    }

    // MARK: - Conversations Management
    func newConversation(title: String? = nil) {
        // Save current conversation messages if there's a selected conversation
        if let currentId = selectedConversationId,
           let currentIndex = conversations.firstIndex(where: { $0.id == currentId }) {
            conversations[currentIndex].messages = chatMessages
        }

        let inferredTitle: String
        if let title = title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inferredTitle = title
        } else if let firstUser = chatMessages.first(where: { $0.isUser })?.text, !firstUser.isEmpty {
            inferredTitle = String(firstUser.prefix(40))
        } else {
            inferredTitle = "New Chat"
        }
        let conv = Conversation(title: inferredTitle)
        conversations.insert(conv, at: 0)
        // switch selection
        selectedConversationId = conv.id
        chatMessages = []
        save()
        print("🆕 Created new conversation: \(inferredTitle)")
    }

    func selectConversation(_ id: UUID) {
        guard let conversation = conversations.first(where: { $0.id == id }) else {
            print("❌ Conversation not found: \(id)")
            return
        }

        // Save current conversation messages if there's a selected conversation
        if let currentId = selectedConversationId,
           let currentIndex = conversations.firstIndex(where: { $0.id == currentId }) {
            conversations[currentIndex].messages = chatMessages
            print("💾 Saved \(chatMessages.count) messages to current conversation")
        }

        // Switch to new conversation
        selectedConversationId = id
        chatMessages = conversation.messages
        save()
        print("🔄 Switched to conversation: \(conversation.title) with \(conversation.messages.count) messages")
    }

    func renameConversation(_ id: UUID, to newTitle: String) {
        guard let idx = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[idx].title = newTitle
        save()
    }

    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        // If deleting current, reset to first if exists
        if selectedConversationId == id {
            selectedConversationId = conversations.first?.id
            chatMessages = conversations.first?.messages ?? []
        }
        save()
    }

    func clearChatMessages() {
        chatMessages.removeAll()
        save()
        print("🗑️ Cleared all chat messages")
    }

    // MARK: - Thoughts Management
    func addThought(_ thought: Thought) {
        thoughts.append(thought)
        save()
        print("📝 Added thought: \(thought.title)")
    }

    // MARK: - Tasks Management
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        save()
        print("✅ Added task: \(task.title)")
        if let due = task.dueDate { NotificationsManager.scheduleTaskReminder(id: task.id, title: task.title, date: due) }
    }
    func toggleTask(_ taskId: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[idx].isCompleted.toggle()
        save()
    }
    func removeTask(_ taskId: UUID) {
        tasks.removeAll { $0.id == taskId }
        save()
        NotificationsManager.cancelTaskReminder(id: taskId)
    }
    func updateTaskDueDate(_ taskId: UUID, newDate: Date?) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let old = tasks[idx]
        // Cancel old reminder if any
        NotificationsManager.cancelTaskReminder(id: old.id)
        // Persist conversations via snapshot

        tasks[idx].dueDate = newDate
        save()
        // Reschedule if applicable
        if let due = newDate, !tasks[idx].isCompleted {
            NotificationsManager.scheduleTaskReminder(id: old.id, title: old.title, date: due)
        }
    }


    // MARK: - Notifications
    func requestNotificationPermissionsIfNeeded() {
        NotificationsManager.requestAuthorization { granted in
            print("🔔 Notifications permission: \(granted)")
        }
    }

    // MARK: - Sample Data
    func createSampleData() {
        print("🎭 Creating sample chat messages...")
        let samples = [
            ChatMessage(text: "Welcome to Mono — ask anything!", isUser: false),
            ChatMessage(text: "What are the best beaches in Los Angeles?", isUser: true)
        ]
        for m in samples { chatMessages.append(m) }

        // Example Thought sample
        let sampleThought = Thought(
            title: "Sample Note",
            tags: ["idea","product"],
            keyPoints: ["Mono uses cassette palette"],
            actionItems: ["Add calendar view"],
            keyInsights: ["Users like scannable cards"]
        )
        thoughts.append(sampleThought)
        print("✅ Sample data created (in-memory)")
    }

    // MARK: - Utility Methods
    func reset() {
        chatMessages.removeAll()
        thoughts.removeAll()
        createSampleData()
        save()
        print("🔄 Data reset to sample state")
    }

    // MARK: - Persistence
    private func snapshot() -> AppDataSnapshot {
        AppDataSnapshot(
            chatMessages: chatMessages.map { $0.toDTO() },
            conversations: conversations.map { $0.toDTO() },
            thoughts: thoughts.map { $0.toDTO() },
            tasks: tasks.map { $0.toDTO() },
            intelligentReferences: intelligentReferences.map { $0.toDTO() },
            conversationInsights: conversationInsights.map { $0.toDTO() }
        )
    }

    private func applySnapshot(_ snap: AppDataSnapshot) {
        chatMessages = snap.chatMessages.map { ChatMessage.fromDTO($0) }
        conversations = (snap.conversations ?? []).map { Conversation.fromDTO($0) }
        // set selection to first existing conversation if any
        selectedConversationId = conversations.first?.id
        if let first = conversations.first { chatMessages = first.messages }
        thoughts = (snap.thoughts ?? []).map { Thought.fromDTO($0) }
        tasks = (snap.tasks ?? []).map { TaskItem.fromDTO($0) }
        intelligentReferences = (snap.intelligentReferences ?? []).map { IntelligentReference.fromDTO($0) }
        conversationInsights = (snap.conversationInsights ?? []).map { ConversationInsight.fromDTO($0) }
    }

    func save() {
        do {
            let snap = snapshot()
            let data = try JSONEncoder().encode(snap)
            try data.write(to: PersistencePaths.dataURL, options: .atomic)
            print("💾 Saved app data locally (iCloud sync if enabled): \(PersistencePaths.dataURL.path)")
        } catch {
            print("❌ Failed to save app data locally: \(error)")
        }
    }

    func load() {
        do {
            let url = PersistencePaths.dataURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("ℹ️ No existing data file at: \(url.path)")
                return
            }
            let data = try Data(contentsOf: url)
            let snap = try JSONDecoder().decode(AppDataSnapshot.self, from: data)
            applySnapshot(snap)
            print("📥 Loaded app data from: \(url.path)")
        } catch {
            print("❌ Failed to load app data: \(error)")
        }
    }
    
    // MARK: - Smart Cross-Referencing
    
    func generateIntelligentReferences(for conversationId: UUID) async {
        guard let currentConversation = conversations.first(where: { $0.id == conversationId }) else { return }
        
        let currentContent = currentConversation.messages.map { $0.text }.joined(separator: "\n")
        
        // Check against other conversations
        var foundReferences: [IntelligentReference] = []
        for otherConversation in conversations where otherConversation.id != conversationId {
            let otherContent = otherConversation.messages.map { $0.text }.joined(separator: "\n")
            
            if let reference = await findIntelligentConnection(
                currentContent: currentContent,
                otherContent: otherContent,
                otherConversationId: otherConversation.id
            ) {
                foundReferences.append(reference)
            }
        }
        
        // Update on main actor with local copy
        let referencesToAdd = foundReferences
        await MainActor.run {
            intelligentReferences.append(contentsOf: referencesToAdd)
            save()
        }
    }
    
    private func findIntelligentConnection(currentContent: String, otherContent: String, otherConversationId: UUID) async -> IntelligentReference? {
        do {
            let prompt = """
            Analyze these two conversations and determine if there are meaningful connections. If you find a connection, extract the most relevant quote from the previous conversation and explain why it's relevant.
            
            Current conversation:
            \(currentContent.prefix(800))
            
            Previous conversation:
            \(otherContent.prefix(800))
            
            Respond with JSON format:
            {"has_connection": true/false, "quote": "exact quote", "context": "why relevant", "confidence": 0.0-1.0, "connection_type": "similar/causal/contradictory/elaborative"}
            
            Only respond if confidence > 0.3. Return {"has_connection": false} if no meaningful connection.
            """
            
            let response = try await AIServiceManager.shared.sendChatMessage(
                messages: [ChatMessage(text: prompt, isUser: true)],
                systemPrompt: "You are an intelligent cross-reference system. Be precise and conservative.",
                temperature: 0.2
            )
            
            // Parse JSON response
            guard let data = response.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let hasConnection = json["has_connection"] as? Bool,
                  hasConnection,
                  let quote = json["quote"] as? String,
                  let context = json["context"] as? String,
                  let confidence = json["confidence"] as? Double,
                  let connectionType = json["connection_type"] as? String,
                  confidence > 0.3 else {
                return nil
            }
            
            return IntelligentReference(
                sourceConversationId: otherConversationId,
                relevantQuote: quote,
                contextSummary: context,
                confidenceScore: Float(confidence),
                connectionType: connectionType
            )
            
        } catch {
            print("❌ Failed to generate intelligent reference: \(error)")
            return nil
        }
    }
    
    func getReferencesForConversation(_ conversationId: UUID) -> [IntelligentReference] {
        return intelligentReferences.filter { ref in
            conversations.contains { $0.id == conversationId }
        }
    }
}
