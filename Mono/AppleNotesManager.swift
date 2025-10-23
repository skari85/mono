//
//  AppleNotesManager.swift
//  Mono
//
//  Apple Notes Integration Manager
//

import Foundation
import EventKit
import SwiftUI

class AppleNotesManager: ObservableObject {
    static let shared = AppleNotesManager()
    
    @Published var hasNotesAccess = false
    @Published var notes: [EKNote] = []
    @Published var lastError: String?
    
    private let eventStore = EKEventStore()
    
    private init() {
        checkNotesAccess()
    }
    
    // MARK: - Notes Access
    
    func checkNotesAccess() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .notDetermined:
            hasNotesAccess = false
            requestNotesAccess()
        case .restricted:
            hasNotesAccess = false
        case .denied:
            hasNotesAccess = false
        case .authorized:
            hasNotesAccess = true
            loadNotes()
        case .fullAccess:
            hasNotesAccess = true
            loadNotes()
        @unknown default:
            hasNotesAccess = false
        }
    }
    
    func requestNotesAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.hasNotesAccess = true
                        self?.loadNotes()
                    } else {
                        self?.hasNotesAccess = false
                        self?.lastError = error?.localizedDescription ?? "Notes access denied"
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.hasNotesAccess = true
                        self?.loadNotes()
                    } else {
                        self?.hasNotesAccess = false
                        self?.lastError = error?.localizedDescription ?? "Notes access denied"
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Management
    
    func loadNotes() {
        guard hasNotesAccess else { return }
        
        // Note: EKEventStore doesn't have direct access to Notes app
        // We'll use a workaround with reminders that can store notes
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            DispatchQueue.main.async {
                if let reminders = reminders {
                    // Convert reminders to notes-like objects
                    self?.notes = reminders.compactMap { reminder in
                        if let notes = reminder.notes, !notes.isEmpty {
                            return EKNote(
                                title: reminder.title,
                                content: notes,
                                createdDate: reminder.creationDate ?? Date(),
                                modifiedDate: reminder.lastModifiedDate ?? Date()
                            )
                        }
                        return nil
                    }
                }
            }
        }
    }
    
    func createNote(title: String, content: String) async -> Bool {
        guard hasNotesAccess else { return false }
        
        do {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = title
            reminder.notes = content
            reminder.calendar = eventStore.defaultCalendarForNewReminders()
            
            try eventStore.save(reminder, commit: true)
            
            await MainActor.run {
                loadNotes()
            }
            
            return true
        } catch {
            await MainActor.run {
                lastError = "Failed to create note: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func searchNotes(query: String) -> [EKNote] {
        guard !query.isEmpty else { return notes }
        
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getRecentNotes(limit: Int = 10) -> [EKNote] {
        return Array(notes.sorted { $0.modifiedDate > $1.modifiedDate }.prefix(limit))
    }
    
    func getNotesByDateRange(startDate: Date, endDate: Date) -> [EKNote] {
        return notes.filter { note in
            note.createdDate >= startDate && note.createdDate <= endDate
        }
    }
}

// MARK: - Supporting Models

struct EKNote: Identifiable, Codable {
    var id = UUID()
    let title: String
    let content: String
    let createdDate: Date
    let modifiedDate: Date
    
    var preview: String {
        return String(content.prefix(100))
    }
    
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}

// MARK: - Notes Integration Extensions

extension AppleNotesManager {
    
    func exportConversationToNotes(_ conversation: Conversation) async -> Bool {
        let title = conversation.title
        let content = conversation.messages.map { message in
            let prefix = message.isUser ? "You: " : "Mono: "
            return "\(prefix)\(message.text)"
        }.joined(separator: "\n\n")
        
        return await createNote(title: title, content: content)
    }
    
    func createNoteFromSummary(_ summary: String, title: String = "AI Summary") async -> Bool {
        return await createNote(title: title, content: summary)
    }
    
    func createNoteFromTask(_ task: TaskItem) async -> Bool {
        let title = task.title
        let content = """
        Task: \(task.title)
        Priority: \(task.priority.rawValue)
        Status: \(task.isCompleted ? "Completed" : "Pending")
        Created: \(task.createdAt.formatted())
        \(task.dueDate != nil ? "Due: \(task.dueDate!.formatted())" : "")
        """
        
        return await createNote(title: title, content: content)
    }
}
