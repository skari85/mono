//  ConversationSidebar.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-10.
//

import SwiftUI

struct ConversationSidebar: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @Binding var isVisible: Bool
    @State private var editingConversationId: UUID?
    @State private var editingTitle: String = ""
    
    var onConversationSelected: (UUID) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Conversations")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("\(dataManager.conversations.count) chats")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isVisible = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Conversations List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(groupedConversations.keys.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { group in
                        ConversationGroupSection(
                            group: group,
                            conversations: groupedConversations[group] ?? [],
                            selectedConversationId: dataManager.selectedConversationId,
                            editingConversationId: $editingConversationId,
                            editingTitle: $editingTitle,
                            onConversationSelected: onConversationSelected,
                            onRename: { id, title in
                                dataManager.renameConversation(id, to: title)
                            },
                            onDelete: { id in
                                dataManager.deleteConversation(id)
                            }
                        )
                    }
                    
                    // Empty state
                    if dataManager.conversations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No conversations yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Start a new chat to see your conversations here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 60)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .frame(width: 280)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 2, y: 0)
    }
    
    private var groupedConversations: [ConversationGroup: [Conversation]] {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [ConversationGroup: [Conversation]] = [:]
        
        for conversation in dataManager.conversations.sorted(by: { $0.createdAt > $1.createdAt }) {
            let group = ConversationGroup.from(date: conversation.createdAt, relativeTo: now, calendar: calendar)
            groups[group, default: []].append(conversation)
        }
        
        return groups
    }
}

struct ConversationGroupSection: View {
    let group: ConversationGroup
    let conversations: [Conversation]
    let selectedConversationId: UUID?
    @Binding var editingConversationId: UUID?
    @Binding var editingTitle: String
    
    let onConversationSelected: (UUID) -> Void
    let onRename: (UUID, String) -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group Header
            HStack {
                Text(group.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                Spacer()
            }
            
            // Conversations in this group
            ForEach(conversations) { conversation in
                ConversationRow(
                    conversation: conversation,
                    isSelected: selectedConversationId == conversation.id,
                    isEditing: editingConversationId == conversation.id,
                    editingTitle: $editingTitle,
                    onTap: { onConversationSelected(conversation.id) },
                    onStartEdit: {
                        editingConversationId = conversation.id
                        editingTitle = conversation.title
                    },
                    onFinishEdit: {
                        if !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onRename(conversation.id, editingTitle)
                        }
                        editingConversationId = nil
                        editingTitle = ""
                    },
                    onDelete: { onDelete(conversation.id) }
                )
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editingTitle: String
    
    let onTap: () -> Void
    let onStartEdit: () -> Void
    let onFinishEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Conversation content
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("Conversation title", text: $editingTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(onFinishEdit)
                } else {
                    Text(conversation.title)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .accentColor : .primary)
                        .lineLimit(1)
                    
                    if let lastMessage = conversation.messages.last {
                        Text(lastMessage.text)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
            
            // Actions menu
            if !isEditing {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        onStartEdit()
                    }
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
        .alert("Delete Conversation", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This conversation will be permanently deleted.")
        }
    }
}

// MARK: - Conversation Grouping Logic

enum ConversationGroup: Hashable {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case older
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .lastWeek: return "Last 7 days"
        case .lastMonth: return "Last 30 days"
        case .older: return "Older"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .today: return 0
        case .yesterday: return 1
        case .lastWeek: return 2
        case .lastMonth: return 3
        case .older: return 4
        }
    }
    
    static func from(date: Date, relativeTo now: Date, calendar: Calendar) -> ConversationGroup {
        let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        
        switch daysDifference {
        case 0:
            return .today
        case 1:
            return .yesterday
        case 2...7:
            return .lastWeek
        case 8...30:
            return .lastMonth
        default:
            return .older
        }
    }
}
