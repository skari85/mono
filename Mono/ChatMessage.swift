//
//  ChatMessage.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation
import SwiftData

@Model
class ChatMessage: Identifiable {
    @Attribute(.unique) var id = UUID()
    var text: String
    var isUser: Bool
    var timestamp: Date

    // Handwritten mode properties
    var isHandwritten: Bool
    var handwritingStyle: String // Raw value of HandwritingStyle enum

    init(text: String, isUser: Bool, isHandwritten: Bool = false, handwritingStyle: HandwritingStyle = .casual) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.isHandwritten = isHandwritten
        self.handwritingStyle = handwritingStyle.rawValue
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
