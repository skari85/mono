//  Persistence.swift
import SwiftUI
extension Notification.Name {
    static let presentSummarizeOverlay = Notification.Name("presentSummarizeOverlay")
    static let startSummarizeAutoRecord = Notification.Name("startSummarizeAutoRecord")
    static let scrollChatToBottom = Notification.Name("scrollChatToBottom")
}

//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import Foundation

// DTOs for persistence (decoupled from ObservableObject classes)
struct ChatMessageDTO: Codable, Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    let isHandwritten: Bool
    let handwritingStyle: String
    let hasAudioRecording: Bool
    let recordingId: UUID?
}

struct SavedConversationDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let messages: [ChatMessageDTO]
}


struct ThoughtDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let languageCode: String?
    let tags: [String]
    let keyPoints: [String]
    let actionItems: [String]
    let keyInsights: [String]
    let sourceTranscript: String?
}

struct TaskItemDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let isCompleted: Bool
    let priority: TaskPriority
    let createdAt: Date
    let sourceThoughtId: UUID?
}

struct AppDataSnapshot: Codable {
    var chatMessages: [ChatMessageDTO]
    var conversations: [SavedConversationDTO]? // optional for backward compatibility
    var thoughts: [ThoughtDTO]? // backward compatible
    var tasks: [TaskItemDTO]? // optional for backward compatibility
}

enum PersistencePaths {
    static func documentsURL(filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }
    static var dataURL: URL { documentsURL(filename: "app_data.json") }
}

extension ChatMessage {
    func toDTO() -> ChatMessageDTO {
        ChatMessageDTO(
            id: id,
            text: text,
            isUser: isUser,
            timestamp: timestamp,
            isHandwritten: isHandwritten,
            handwritingStyle: handwritingStyle,
            hasAudioRecording: hasAudioRecording,
            recordingId: recordingId
        )
    }
    static func fromDTO(_ dto: ChatMessageDTO) -> ChatMessage {
        let msg = ChatMessage(text: dto.text, isUser: dto.isUser, isHandwritten: dto.isHandwritten, handwritingStyle: HandwritingStyle(rawValue: dto.handwritingStyle) ?? .casual, hasAudioRecording: dto.hasAudioRecording, recordingId: dto.recordingId)
        // Overwrite generated values
        msg.timestamp = dto.timestamp
        // Note: ChatMessage.id is let UUID(), not settable; to preserve identity we can accept a new UUID since app logic relies mostly on order and file naming uses new ids at record time.
        return msg
    }
}

extension Thought {
    func toDTO() -> ThoughtDTO {
        ThoughtDTO(
            id: id,
            title: title,
            createdAt: createdAt,
            languageCode: languageCode,
            tags: tags,
            keyPoints: keyPoints,
            actionItems: actionItems,
            keyInsights: keyInsights,
            sourceTranscript: sourceTranscript
        )
    }
    static func fromDTO(_ dto: ThoughtDTO) -> Thought {
        Thought(
            id: dto.id,
            title: dto.title,
            createdAt: dto.createdAt,
            languageCode: dto.languageCode,
            tags: dto.tags,
            keyPoints: dto.keyPoints,
            actionItems: dto.actionItems,
            keyInsights: dto.keyInsights,
            sourceTranscript: dto.sourceTranscript
        )
    }
}

extension TaskItem {
    func toDTO() -> TaskItemDTO {
        TaskItemDTO(id: id, title: title, dueDate: dueDate, isCompleted: isCompleted, priority: priority, createdAt: createdAt, sourceThoughtId: sourceThoughtId)
    }
    static func fromDTO(_ dto: TaskItemDTO) -> TaskItem {
        TaskItem(id: dto.id, title: dto.title, dueDate: dto.dueDate, isCompleted: dto.isCompleted, priority: dto.priority, createdAt: dto.createdAt, sourceThoughtId: dto.sourceThoughtId)
    }
}

extension Conversation {
    func toDTO() -> SavedConversationDTO {
        SavedConversationDTO(id: id, title: title, createdAt: createdAt, messages: messages.map { $0.toDTO() })
    }
    static func fromDTO(_ dto: SavedConversationDTO) -> Conversation {
        Conversation(id: dto.id, title: dto.title, createdAt: dto.createdAt, messages: dto.messages.map { ChatMessage.fromDTO($0) })
    }
}


