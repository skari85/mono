//  Persistence.swift
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

struct AppDataSnapshot: Codable {
    var chatMessages: [ChatMessageDTO]
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


