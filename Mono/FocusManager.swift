//
//  FocusManager.swift
//  Mono
//
//  Focus Modes integration for context-aware behavior
//

import Foundation
import SwiftUI

final class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var currentFocusMode: FocusMode = .unknown
    @Published var isWorkFocusActive = false
    @Published var isPersonalFocusActive = false
    
    private init() {
        detectCurrentFocus()
        // Set up notification observers for focus changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(focusDidChange),
            name: .NSExtensionHostDidBecomeActive,
            object: nil
        )
    }
    
    enum FocusMode: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
        case doNotDisturb = "Do Not Disturb"
        case sleep = "Sleep"
        case fitness = "Fitness"
        case driving = "Driving"
        case unknown = "Unknown"
        
        var suggestedPersonality: PersonalityMode {
            switch self {
            case .work:
                return .smart
            case .personal:
                return .play
            case .doNotDisturb, .sleep:
                return .quiet
            default:
                return .smart
            }
        }
        
        var conversationFilter: ConversationFilter {
            switch self {
            case .work:
                return .workRelated
            case .personal:
                return .personal
            default:
                return .all
            }
        }
    }
    
    enum ConversationFilter: String, CaseIterable {
        case all = "All"
        case workRelated = "Work"
        case personal = "Personal"
        case creative = "Creative"
        
        func shouldShow(_ conversation: Conversation) -> Bool {
            switch self {
            case .all:
                return true
            case .workRelated:
                return conversation.containsWorkKeywords()
            case .personal:
                return conversation.containsPersonalKeywords()
            case .creative:
                return conversation.containsCreativeKeywords()
            }
        }
    }
    
    // MARK: - Focus Detection
    
    private func detectCurrentFocus() {
        // Use available iOS APIs to detect current Focus mode
        // Note: Direct Focus detection requires specific entitlements
        // For now, we'll use heuristics and user preferences
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Smart defaults based on time
        if hour >= 9 && hour <= 17 {
            currentFocusMode = .work
            isWorkFocusActive = true
        } else if hour >= 22 || hour <= 6 {
            currentFocusMode = .doNotDisturb
        } else {
            currentFocusMode = .personal
            isPersonalFocusActive = true
        }
    }
    
    @objc private func focusDidChange() {
        detectCurrentFocus()
    }
    
    // MARK: - Focus-Aware Behavior
    
    func getFilteredConversations(_ conversations: [Conversation]) -> [Conversation] {
        let filter = currentFocusMode.conversationFilter
        return conversations.filter { filter.shouldShow($0) }
    }
    
    func getSuggestedPersonality() -> PersonalityMode {
        return currentFocusMode.suggestedPersonality
    }
    
    func getContextualPrompts() -> [String] {
        switch currentFocusMode {
        case .work:
            return [
                "Help me prioritize my tasks",
                "Draft a professional email",
                "Analyze this data",
                "Plan my next meeting"
            ]
        case .personal:
            return [
                "What should I cook for dinner?",
                "Plan a weekend activity",
                "Help me learn something new",
                "Creative writing prompt"
            ]
        case .doNotDisturb, .sleep:
            return [
                "Quick question",
                "Set a reminder",
                "Brief summary",
                "Simple answer"
            ]
        default:
            return [
                "What's on your mind?",
                "Tell me something interesting",
                "Help me think through this",
                "Quick brainstorm"
            ]
        }
    }
    
    // MARK: - Manual Focus Override
    
    func setFocusMode(_ mode: FocusMode) {
        currentFocusMode = mode
        isWorkFocusActive = (mode == .work)
        isPersonalFocusActive = (mode == .personal)
        
        // Save user preference
        UserDefaults.standard.set(mode.rawValue, forKey: "manual_focus_override")
    }
    
    func clearFocusOverride() {
        UserDefaults.standard.removeObject(forKey: "manual_focus_override")
        detectCurrentFocus()
    }
}

// MARK: - Conversation Extensions

extension Conversation {
    func containsWorkKeywords() -> Bool {
        let workKeywords = ["meeting", "project", "deadline", "work", "office", "client", "business", "strategy", "report", "email", "presentation", "team", "manager", "boss", "colleague", "budget", "revenue", "profit", "sales", "marketing", "development", "code", "programming", "design", "analysis", "data", "metrics", "kpi", "task", "schedule", "calendar", "appointment"]
        
        let allText = (title + " " + messages.map { $0.text }.joined(separator: " ")).lowercased()
        
        return workKeywords.contains { keyword in
            allText.contains(keyword)
        }
    }
    
    func containsPersonalKeywords() -> Bool {
        let personalKeywords = ["family", "friend", "relationship", "hobby", "vacation", "travel", "home", "personal", "health", "fitness", "cooking", "recipe", "movie", "book", "music", "game", "sport", "weekend", "evening", "dinner", "lunch", "shopping", "gift", "birthday", "holiday", "fun", "entertainment", "social", "date", "party", "celebration", "kids", "children", "parent", "mom", "dad", "sibling", "pet", "dog", "cat"]
        
        let allText = (title + " " + messages.map { $0.text }.joined(separator: " ")).lowercased()
        
        return personalKeywords.contains { keyword in
            allText.contains(keyword)
        }
    }
    
    func containsCreativeKeywords() -> Bool {
        let creativeKeywords = ["creative", "art", "design", "writing", "story", "idea", "inspiration", "brainstorm", "concept", "innovation", "imagination", "artistic", "creative", "paint", "draw", "write", "compose", "create", "invent", "explore", "experiment", "dream", "vision", "aesthetic", "style", "beauty", "expression", "original", "unique", "novel", "poetry", "music", "dance", "theater", "film", "photography"]
        
        let allText = (title + " " + messages.map { $0.text }.joined(separator: " ")).lowercased()
        
        return creativeKeywords.contains { keyword in
            allText.contains(keyword)
        }
    }
}
