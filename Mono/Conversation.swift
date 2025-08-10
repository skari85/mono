//  Conversation.swift
//  Mono

import Foundation
import SwiftUI

class Conversation: Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    let createdAt: Date
    @Published var messages: [ChatMessage]

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.messages = messages
    }
}

