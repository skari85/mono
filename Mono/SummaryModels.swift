import Foundation
import SwiftUI

struct StructuredSummary: Codable {
    var tags: [String]
    var keyPoints: [String]
    var actionItems: [String]
    var keyInsights: [String]

    enum CodingKeys: String, CodingKey {
        case tags
        case keyPoints = "key_points"
        case actionItems = "action_items"
        case keyInsights = "key_insights"
    }
}

extension StructuredSummary {
    func toMarkdown() -> String {
        var out: [String] = []
        if !keyPoints.isEmpty {
            out.append("## Key Points\n" + keyPoints.map { "- \($0)" }.joined(separator: "\n"))
        }
        if !actionItems.isEmpty {
            out.append("## Action Items\n" + actionItems.map { "- \($0)" }.joined(separator: "\n"))
        }
        if !keyInsights.isEmpty {
            out.append("## Key Insights\n" + keyInsights.map { "- \($0)" }.joined(separator: "\n"))
        }
        if !tags.isEmpty {
            out.append("Tags: " + tags.joined(separator: ", "))
        }
        return out.joined(separator: "\n\n")
    }
    func toJSON(pretty: Bool = true) -> String {
        let encoder = JSONEncoder()
        if pretty { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let obj: [String: Any] = [
            "tags": tags,
            "key_points": keyPoints,
            "action_items": actionItems,
            "key_insights": keyInsights
        ]
        // Serialize via JSONSerialization for explicit control
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: pretty ? [.prettyPrinted, .sortedKeys] : []) {
            return String(data: data, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }
}

// MARK: - Lightweight UI helpers for color-coded sheets
struct TagChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.cassetteBlue.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(Color.cassetteBlue.opacity(0.35), lineWidth: 0.5)
            )
            .foregroundColor(.cassetteBlue)
    }
}

struct ColorSheetSection: View {
    let title: String
    let color: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.cassetteTextDark)
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(color).frame(width: 6, height: 6).padding(.top, 6)
                    Text(item).foregroundColor(.cassetteTextDark)
                }
            }
        }
        .padding(12)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 3)
                .fill(color.opacity(0.12))
        )
    }
}

