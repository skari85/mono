import Foundation
import SwiftUI

// A persisted thought/note with structured sections rendered as color-coded sheets
final class Thought: Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var createdAt: Date
    @Published var languageCode: String?
    @Published var tags: [String]
    @Published var keyPoints: [String]
    @Published var actionItems: [String]
    @Published var keyInsights: [String]
    @Published var sourceTranscript: String?

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), languageCode: String? = nil, tags: [String] = [], keyPoints: [String] = [], actionItems: [String] = [], keyInsights: [String] = [], sourceTranscript: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.languageCode = languageCode
        self.tags = tags
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.keyInsights = keyInsights
        self.sourceTranscript = sourceTranscript
    }
}

