//
//  DataManager.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation
import SwiftUI

// MARK: - Simple In-Memory Data Manager
class DataManager: ObservableObject {
    static let shared = DataManager()

    // In-memory storage
    @Published var chatMessages: [ChatMessage] = []

    private init() {
        print("🔧 DataManager initialized")
        load()
        if chatMessages.isEmpty {
            createSampleData()
            save()
        }
    }

    // MARK: - Chat Message Management
    func addChatMessage(_ message: ChatMessage) {
        chatMessages.append(message)
        save()
        print("💬 Added chat message: \(message.text)")
    }

    func clearChatMessages() {
        chatMessages.removeAll()
        save()
        print("🗑️ Cleared all chat messages")
    }


    // MARK: - Sample Data
    func createSampleData() {
        print("🎭 Creating sample chat messages...")
        let samples = [
            ChatMessage(text: "Welcome to Mono — ask anything!", isUser: false),
            ChatMessage(text: "What are the best beaches in Los Angeles?", isUser: true)
        ]
        for m in samples { chatMessages.append(m) }
        print("✅ Sample chat messages created (in-memory)")
    }

    // MARK: - Utility Methods
    func reset() {
        chatMessages.removeAll()
        createSampleData()
        save()
        print("🔄 Data reset to sample state")
    }

    // MARK: - Persistence
    private func snapshot() -> AppDataSnapshot {
        AppDataSnapshot(
            chatMessages: chatMessages.map { $0.toDTO() }
        )
    }

    private func applySnapshot(_ snap: AppDataSnapshot) {
        chatMessages = snap.chatMessages.map { ChatMessage.fromDTO($0) }
    }

    func save() {
        do {
            let snap = snapshot()
            let data = try JSONEncoder().encode(snap)
            try data.write(to: PersistencePaths.dataURL, options: .atomic)
            print("💾 Saved app data to: \(PersistencePaths.dataURL.path)")
        } catch {
            print("❌ Failed to save app data: \(error)")
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
}
