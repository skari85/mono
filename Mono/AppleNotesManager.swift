//
//  AppleNotesManager.swift
//  Mono
//
//  Apple Notes integration for conversation export
//

import Foundation
import EventKit

final class AppleNotesManager: ObservableObject {
    static let shared = AppleNotesManager()
    
    private init() {}
    
    // MARK: - Export to Apple Notes
    
    func exportConversationToNotes(_ conversation: Conversation) async -> URL? {
        let formattedContent = formatConversationForNotes(conversation)
        
        // Create a temporary file that can be shared to Notes
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(conversation.title).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try formattedContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Failed to create notes file: \(error)")
            return nil
        }
    }
    
    private func formatConversationForNotes(_ conversation: Conversation) -> String {
        var content = ""
        
        // Title and metadata
        content += "# \(conversation.title)\n\n"
        content += "**Created:** \(DateFormatter.readable.string(from: conversation.createdAt))\n"
        content += "**Messages:** \(conversation.messages.count)\n\n"
        
        // Add conversation tags if available
        let tags = extractTags(from: conversation)
        if !tags.isEmpty {
            content += "**Tags:** \(tags.joined(separator: ", "))\n\n"
        }
        
        content += "---\n\n"
        
        // Conversation content
        for (index, message) in conversation.messages.enumerated() {
            let speaker = message.isUser ? "👤 You" : "🤖 Mono"
            let timestamp = DateFormatter.timeOnly.string(from: message.timestamp)
            
            content += "## \(speaker) (\(timestamp))\n\n"
            content += "\(message.text)\n\n"
            
            // Add separator between messages
            if index < conversation.messages.count - 1 {
                content += "---\n\n"
            }
        }
        
        // Add summary section
        content += "\n## Summary\n\n"
        content += "This conversation was exported from Mono on \(DateFormatter.readable.string(from: Date())).\n"
        content += "Total duration: \(conversationDuration(conversation))\n"
        
        return content
    }
    
    private func extractTags(from conversation: Conversation) -> [String] {
        let allText = conversation.messages.map { $0.text }.joined(separator: " ").lowercased()
        var tags: [String] = []
        
        // Work-related tags
        if allText.contains("work") || allText.contains("project") || allText.contains("meeting") {
            tags.append("work")
        }
        
        // Personal tags
        if allText.contains("personal") || allText.contains("family") || allText.contains("friend") {
            tags.append("personal")
        }
        
        // Creative tags
        if allText.contains("creative") || allText.contains("idea") || allText.contains("design") {
            tags.append("creative")
        }
        
        // Learning tags
        if allText.contains("learn") || allText.contains("understand") || allText.contains("explain") {
            tags.append("learning")
        }
        
        // Decision tags
        if allText.contains("decide") || allText.contains("choose") || allText.contains("option") {
            tags.append("decision")
        }
        
        return tags
    }
    
    private func conversationDuration(_ conversation: Conversation) -> String {
        guard let firstMessage = conversation.messages.first,
              let lastMessage = conversation.messages.last else {
            return "Unknown"
        }
        
        let duration = lastMessage.timestamp.timeIntervalSince(firstMessage.timestamp)
        
        if duration < 60 {
            return "< 1 minute"
        } else if duration < 3600 {
            let minutes = Int(duration / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
    
    // MARK: - Share Sheet Integration
    
    func createShareableContent(for conversation: Conversation) -> [Any] {
        var items: [Any] = []
        
        // Add formatted text
        let formattedText = formatConversationForNotes(conversation)
        items.append(formattedText)
        
        // Add temporary file URL for better integration
        if let fileURL = try? createTemporaryFile(content: formattedText, fileName: conversation.title) {
            items.append(fileURL)
        }
        
        return items
    }
    
    private func createTemporaryFile(content: String, fileName: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let sanitizedFileName = fileName.replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)
        let fileURL = tempDir.appendingPathComponent("\(sanitizedFileName).txt")
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
