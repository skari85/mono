//
//  CalendarIntegrationView.swift
//  Mono
//
//  Calendar Integration UI Components
//

import SwiftUI
import EventKit

// MARK: - Calendar Widget for Main Interface

struct CalendarWidget: View {
    @EnvironmentObject private var calendarManager: CalendarManager
    @State private var isExpanded = false
    
    var body: some View {
        if calendarManager.hasCalendarAccess && (!calendarManager.todaysEvents.isEmpty || !calendarManager.upcomingEvents.isEmpty) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.cassetteTeal)
                        .font(.title3)
                    
                    Text("Calendar")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.cassetteTextMedium)
                            .font(.caption)
                    }
                }
                
                if isExpanded {
                    // Today's Events
                    if !calendarManager.todaysEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.cassetteTeal)
                            
                            ForEach(calendarManager.todaysEvents.prefix(3), id: \.eventIdentifier) { event in
                                CalendarEventRow(event: event, showDate: false)
                            }
                        }
                    }
                    
                    // Upcoming Events
                    if !calendarManager.upcomingEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upcoming")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            
                            ForEach(calendarManager.upcomingEvents.prefix(3), id: \.eventIdentifier) { event in
                                CalendarEventRow(event: event, showDate: true)
                            }
                        }
                    }
                } else {
                    // Compact view
                    let nextEvent = calendarManager.todaysEvents.first ?? calendarManager.upcomingEvents.first
                    if let event = nextEvent {
                        CalendarEventRow(event: event, showDate: !Calendar.current.isDateInToday(event.startDate), isCompact: true)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cassetteTeal.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cassetteTeal.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: EKEvent
    let showDate: Bool
    var isCompact: Bool = false

    @EnvironmentObject private var calendarManager: CalendarManager
    @State private var showingAIDiscussion = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                if event.isAllDay {
                    Text("All")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text("Day")
                        .font(.caption2)
                        .fontWeight(.medium)
                } else {
                    Text(DateFormatter.shortTime.string(from: event.startDate))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(.cassetteTeal)
            .frame(width: 40, alignment: .center)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled Event")
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if showDate {
                    Text(DateFormatter.medium.string(from: event.startDate))
                        .font(.caption)
                        .foregroundColor(.cassetteTextMedium)
                }
                
                if let location = event.location, !location.isEmpty, !isCompact {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.cassetteTextMedium)
                    .lineLimit(1)
                }
                
                if !isCompact {
                    // Time until event
                    let timeUntil = timeUntilEvent(event)
                    if !timeUntil.isEmpty {
                        Text(timeUntil)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange.opacity(0.1))
                            )
                    }
                }
            }
            
            Spacer()
            
            // AI Discussion button
            if !isCompact {
                Button(action: { showingAIDiscussion = true }) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.caption)
                        .foregroundColor(.cassetteTeal)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.cassetteTeal.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingAIDiscussion) {
            EventAIDiscussionView(event: event)
        }
    }
    
    private func timeUntilEvent(_ event: EKEvent) -> String {
        let now = Date()
        
        if event.startDate > now {
            let interval = event.startDate.timeIntervalSince(now)
            return "in \(formatTimeInterval(interval))"
        } else if event.endDate > now {
            return "happening now"
        } else {
            return ""
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Event AI Discussion View

struct EventAIDiscussionView: View {
    @Environment(\.dismiss) private var dismiss
    let event: EKEvent

    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var aiServiceManager: AIServiceManager
    @State private var chatViewModel: ChatViewModel?
    @State private var discussionStarted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Event details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.cassetteTeal)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title ?? "Untitled Event")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(formatEventDateRange(event))
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextMedium)
                        }
                        
                        Spacer()
                    }
                    
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "location")
                                .foregroundColor(.orange)
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                    
                    if let notes = event.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.cassetteTextMedium)
                            
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cassetteTeal.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cassetteTeal.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Discussion options
                VStack(spacing: 12) {
                    Text("Discuss with AI")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        DiscussionOptionButton(
                            icon: "questionmark.circle",
                            title: "Prepare for this event",
                            description: "Get suggestions and talking points"
                        ) {
                            startDiscussion(type: "prepare")
                        }
                        
                        DiscussionOptionButton(
                            icon: "clock",
                            title: "Schedule discussion",
                            description: "Plan around this event"
                        ) {
                            startDiscussion(type: "schedule")
                        }
                        
                        DiscussionOptionButton(
                            icon: "lightbulb",
                            title: "Event insights",
                            description: "Analyze and get insights"
                        ) {
                            startDiscussion(type: "insights")
                        }
                        
                        DiscussionOptionButton(
                            icon: "bubble.left.and.bubble.right",
                            title: "General discussion",
                            description: "Open conversation about this event"
                        ) {
                            startDiscussion(type: "general")
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Event Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if chatViewModel == nil {
                chatViewModel = ChatViewModel(dataManager: dataManager)
            }
        }
    }
    
    private func startDiscussion(type: String) {
        let eventForAI = CalendarManager.CalendarEventForAI(
            id: event.eventIdentifier ?? UUID().uuidString,
            title: event.title ?? "Untitled Event",
            startDate: event.startDate,
            endDate: event.endDate,
            location: event.location,
            notes: event.notes,
            attendees: event.attendees?.compactMap { $0.name } ?? [],
            isAllDay: event.isAllDay,
            timeUntilEvent: "",
            context: "discussion"
        )

        let prompt: String
        switch type {
        case "prepare":
            prompt = "I have an upcoming event '\(eventForAI.title)' on \(DateFormatter.medium.string(from: eventForAI.startDate)). Can you help me prepare for it? \(eventForAI.location.map { "It's at \($0). " } ?? "")\(eventForAI.notes.map { "Notes: \($0)" } ?? "")"
        case "schedule":
            prompt = "I have '\(eventForAI.title)' scheduled for \(DateFormatter.medium.string(from: eventForAI.startDate)). Can you help me plan my day around this event?"
        case "insights":
            prompt = "Can you analyze this event for me? '\(eventForAI.title)' on \(DateFormatter.medium.string(from: eventForAI.startDate)). \(eventForAI.notes.map { "Details: \($0)" } ?? "")"
        case "general":
            prompt = eventForAI.discussionPrompt
        default:
            prompt = eventForAI.discussionPrompt
        }

        // Add the message to current conversation and trigger AI response
        let userMessage = ChatMessage(text: prompt, isUser: true)
        dataManager.addChatMessage(userMessage)

        // Trigger AI response
        Task {
            await chatViewModel?.sendMessage(prompt)
        }

        dismiss()
    }
    
    private func formatEventDateRange(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = event.isAllDay ? .none : .short
        
        if event.isAllDay {
            return formatter.string(from: event.startDate)
        } else {
            let start = formatter.string(from: event.startDate)
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let end = formatter.string(from: event.endDate)
            return "\(start) - \(end)"
        }
    }
}

// MARK: - Discussion Option Button

struct DiscussionOptionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.cassetteTeal)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.cassetteTextMedium)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.cassetteTeal)
                    .font(.title3)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar Quick Actions

struct CalendarQuickActions: View {
    @EnvironmentObject private var calendarManager: CalendarManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text("📅 Calendar Actions")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.cassetteTeal)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add Event"
                ) {
                    // Trigger conversation-based event creation
                }
                
                QuickActionButton(
                    icon: "calendar",
                    title: "Today's Events"
                ) {
                    // Show today's events summary
                }
                
                QuickActionButton(
                    icon: "clock",
                    title: "Next Event"
                ) {
                    // Discuss next upcoming event
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.cassetteTeal)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.cassetteTextMedium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cassetteTeal.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

