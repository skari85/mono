//
//  CalendarManager.swift
//  Mono
//
//  Intelligent Calendar Integration for Mono
//

import Foundation
import EventKit

final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    private let eventStore = EKEventStore()
    @Published var hasCalendarAccess = false
    @Published var upcomingEvents: [EKEvent] = []

    private init() {
        checkCalendarAccess()
        Task { await loadUpcomingEvents() }
    }

    // MARK: - Calendar Access
    
    func requestCalendarAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run { hasCalendarAccess = granted }
                if granted { await loadUpcomingEvents() }
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                await MainActor.run { hasCalendarAccess = granted }
                if granted { await loadUpcomingEvents() }
                return granted
            }
        } catch {
            print("❌ Calendar access request failed: \(error)")
            return false
        }
    }
    
    private func checkCalendarAccess() {
        if #available(iOS 17.0, *) {
            hasCalendarAccess = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            hasCalendarAccess = EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }
    
    @MainActor
    func loadUpcomingEvents() async {
        guard hasCalendarAccess else { return }
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        upcomingEvents = Array(events.prefix(10))
    }
    
    // MARK: - Event Creation
    
    func createEventFromConversation(_ conversation: Conversation) async -> EKEvent? {
        guard hasCalendarAccess else { return nil }
        let content = conversation.messages.map { $0.text }.joined(separator: "\n")
        let suggestion = await generateEventSuggestion(from: conversation.title, content: content)
        
        let event = EKEvent(eventStore: eventStore)
        event.title = suggestion.title
        event.notes = suggestion.notes
        event.startDate = suggestion.startDate
        event.endDate = suggestion.endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            await loadUpcomingEvents()
            return event
        } catch {
            print("❌ Failed to save calendar event: \(error)")
            return nil
        }
    }
    
    // MARK: - Suggestion Helper
    
    private func generateEventSuggestion(from title: String, content: String) async -> EventSuggestion {
        let preferredHour = computeTypicalUsageHour()
        let slot = await findNextAvailableSlot(preferredHour: preferredHour, duration: 60 * 60)

        var eventTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if eventTitle.isEmpty { eventTitle = "Mono Chat" }

        var notes = content
        if content.count > 600 {
            let prefix = content.prefix(600)
            notes = String(prefix) + "\n…"
        }

        return EventSuggestion(title: eventTitle, notes: notes, startDate: slot.start, endDate: slot.end)
    }

    // MARK: - Smarter Suggestions

    func findNextAvailableSlot(preferredHour: Int?, duration: TimeInterval) async -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        // Search window: next 14 days
        for dayOffset in 0..<14 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }

            // Candidate hours: preferred hour first (if provided), then working hours 9-17
            var candidateHours: [Int] = []
            if let h = preferredHour { candidateHours.append(h) }
            candidateHours.append(contentsOf: Array(9...17))
            candidateHours = Array(NSOrderedSet(array: candidateHours)) as? [Int] ?? candidateHours

            // Fetch events for the day
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(24*3600)
            let predicate = eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)
            let events = eventStore.events(matching: predicate)

            for hour in candidateHours {
                guard let candidateStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayStart) else { continue }
                // Skip past slots
                if candidateStart < now { continue }
                let candidateEnd = candidateStart.addingTimeInterval(duration)

                // Check overlap
                let overlaps = events.contains { evt in
                    !(evt.endDate <= candidateStart || evt.startDate >= candidateEnd)
                }
                if !overlaps {
                    return (candidateStart, candidateEnd)
                }
            }
        }

        // Fallback: next hour
        let nextHour = calendar.date(bySettingHour: calendar.component(.hour, from: now) + 1, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(3600)
        return (nextHour, nextHour.addingTimeInterval(duration))
    }

    private func computeTypicalUsageHour() -> Int? {
        // Derive a common hour from recent chat activity
        let messages = DataManager.shared.chatMessages.suffix(50)
        guard !messages.isEmpty else { return nil }
        var counts: [Int: Int] = [:]
        for m in messages {
            let hour = Calendar.current.component(.hour, from: m.timestamp)
            counts[hour, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

struct EventSuggestion {
    let title: String
    let notes: String
    let startDate: Date
    let endDate: Date
}


