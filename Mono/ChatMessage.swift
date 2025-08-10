//
//  ChatMessage.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation

// Simple in-memory chat message model
class ChatMessage: Identifiable, ObservableObject {
    let id = UUID()
    @Published var text: String
    @Published var isUser: Bool
    @Published var timestamp: Date

    // Handwritten mode properties
    @Published var isHandwritten: Bool
    @Published var handwritingStyle: String // Raw value of HandwritingStyle enum

    // Audio recording properties
    @Published var hasAudioRecording: Bool = false
    @Published var recordingId: UUID? = nil

    init(text: String, isUser: Bool, isHandwritten: Bool = false, handwritingStyle: HandwritingStyle = .casual, hasAudioRecording: Bool = false, recordingId: UUID? = nil) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.isHandwritten = isHandwritten
        self.handwritingStyle = handwritingStyle.rawValue
        self.hasAudioRecording = hasAudioRecording
        self.recordingId = recordingId
    }

    var handwritingStyleEnum: HandwritingStyle {
        get {
            HandwritingStyle(rawValue: handwritingStyle) ?? .casual
        }
        set {
            handwritingStyle = newValue.rawValue
        }
    }
}
