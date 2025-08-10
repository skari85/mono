import SwiftUI

// Standalone subview to keep SummarizeView body simple
struct StructuredSheetsView: View {
    let s: StructuredSummary
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !s.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(s.tags, id: \.self) { TagChip(text: "#\($0)") } }
                }
            }
            if !s.actionItems.isEmpty {
                ColorSheetSection(title: "Action Items", color: .cassetteSage, items: s.actionItems)
            }
            if !s.keyInsights.isEmpty {
                ColorSheetSection(title: "Key Insights", color: .cassetteBlue, items: s.keyInsights)
            }
            if !s.keyPoints.isEmpty {
                ColorSheetSection(title: "Key Points", color: .cassetteGold, items: s.keyPoints)
            }
        }
    }
}

