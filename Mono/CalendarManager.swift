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
    @Published var todaysEvents: [EKEvent] = []
    @Published var discussableEvents: [CalendarEventForAI] = []
    
    private init() {
        checkCalendarAccess()
        Task { 
            await loadUpcomingEvents()
            await loadTodaysEvents()
            await prepareEventsForAI()
        }
        
        // Start periodic refresh every 5 minutes
        startPeriodicRefresh()
    }
    
    // MARK: - Event Data for AI Discussion
    
    struct CalendarEventForAI: Identifiable, Codable {
        let id: String
        let title: String
        let startDate: Date
        let endDate: Date
        let location: String?
        let notes: String?
        let attendees: [String]
        let isAllDay: Bool
        let timeUntilEvent: String
        let context: String // "upcoming", "today", "past"
        
        var discussionPrompt: String {
            let timeInfo = isAllDay ? "All day" : "\(DateFormatter.shortTime.string(from: startDate)) - \(DateFormatter.shortTime.string(from: endDate))"
            let locationInfo = location.map { " at \($0)" } ?? ""
            let attendeeInfo = attendees.isEmpty ? "" : " with \(attendees.joined(separator: ", "))"
            
            return "I have an event '\(title)' on \(DateFormatter.medium.string(from: startDate)) \(timeInfo)\(locationInfo)\(attendeeInfo). \(notes ?? "")"
        }
    }
    
    @MainActor
    func loadTodaysEvents() async {
        guard hasCalendarAccess else { return }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        todaysEvents = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
    
    @MainActor
    func prepareEventsForAI() async {
        guard hasCalendarAccess else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Get events from yesterday to next week
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        
        let predicate = eventStore.predicateForEvents(withStart: yesterday, end: nextWeek, calendars: nil)
        let allEvents = eventStore.events(matching: predicate)
        
        discussableEvents = allEvents.compactMap { event in
            let context: String
            if calendar.isDateInToday(event.startDate) {
                context = "today"
            } else if event.startDate > now {
                context = "upcoming"
            } else {
                context = "past"
            }
            
            let timeUntil: String
            if event.startDate > now {
                let interval = event.startDate.timeIntervalSince(now)
                timeUntil = formatTimeInterval(interval)
            } else if event.endDate > now {
                timeUntil = "happening now"
            } else {
                let interval = now.timeIntervalSince(event.endDate)
                timeUntil = "\(formatTimeInterval(interval)) ago"
            }
            
            return CalendarEventForAI(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Untitled Event",
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                notes: event.notes,
                attendees: event.attendees?.compactMap { $0.name } ?? [],
                isAllDay: event.isAllDay,
                timeUntilEvent: timeUntil,
                context: context
            )
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    // MARK: - AI Integration Methods
    
    func getEventsForAIDiscussion(context: String = "all") -> [CalendarEventForAI] {
        switch context {
        case "today":
            return discussableEvents.filter { $0.context == "today" }
        case "upcoming":
            return discussableEvents.filter { $0.context == "upcoming" }
        case "past":
            return discussableEvents.filter { $0.context == "past" }
        default:
            return discussableEvents
        }
    }
    
    func generateCalendarSummaryForAI() -> String {
        let todayCount = discussableEvents.filter { $0.context == "today" }.count
        let upcomingCount = discussableEvents.filter { $0.context == "upcoming" }.count
        
        var summary = "Calendar Summary:\n"
        summary += "• Today: \(todayCount) event\(todayCount == 1 ? "" : "s")\n"
        summary += "• Upcoming: \(upcomingCount) event\(upcomingCount == 1 ? "" : "s")\n\n"
        
        // Add today's events
        let todayEvents = getEventsForAIDiscussion(context: "today")
        if !todayEvents.isEmpty {
            summary += "Today's Events:\n"
            for event in todayEvents.prefix(3) {
                let timeInfo = event.isAllDay ? "All day" : DateFormatter.shortTime.string(from: event.startDate)
                summary += "• \(timeInfo): \(event.title)\n"
            }
            summary += "\n"
        }
        
        // Add upcoming events
        let upcomingEvents = getEventsForAIDiscussion(context: "upcoming")
        if !upcomingEvents.isEmpty {
            summary += "Next 3 Upcoming:\n"
            for event in upcomingEvents.prefix(3) {
                summary += "• \(DateFormatter.shortDate.string(from: event.startDate)): \(event.title) (\(event.timeUntilEvent))\n"
            }
        }
        
        return summary
    }
    
    // MARK: - Refresh and Sync
    
    func refreshAllCalendarData() async {
        guard hasCalendarAccess else { return }
        await loadUpcomingEvents()
        await loadTodaysEvents()
        await prepareEventsForAI()
    }
    
    func startPeriodicRefresh() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Refresh every 5 minutes
            Task {
                await self.refreshAllCalendarData()
            }
        }
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
    
    /// Create a calendar event with specific details
    func createEvent(title: String, startDate: Date, duration: TimeInterval, notes: String? = nil) async -> EKEvent? {
        guard hasCalendarAccess else {
            print("❌ No calendar access")
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration)
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            await loadUpcomingEvents()
            await loadTodaysEvents()
            await prepareEventsForAI()
            print("✅ Calendar event created: \(title) at \(startDate)")
            return event
        } catch {
            print("❌ Failed to save calendar event: \(error)")
            return nil
        }
    }
    
    func createEventFromConversation(_ conversation: Conversation) async -> EKEvent? {
        guard hasCalendarAccess else { return nil }
        let content = conversation.messages.map { $0.text }.joined(separator: "\n")
        let suggestion = await generateEventSuggestion(from: conversation.title, content: content)
        
        return await createEvent(
            title: suggestion.title,
            startDate: suggestion.startDate,
            duration: suggestion.endDate.timeIntervalSince(suggestion.startDate),
            notes: suggestion.notes
        )
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

// MARK: - DateFormatter Extensions

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}


