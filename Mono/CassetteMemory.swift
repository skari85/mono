//
//  CassetteMemory.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Cassette Memory Model
@Model
class CassetteMemory: Identifiable {
    @Attribute(.unique) var id = UUID()
    var title: String
    var subtitle: String
    var createdDate: Date
    var lastAccessedDate: Date
    var accessCount: Int
    var cassetteColor: String // Hex color for the cassette
    var labelStyleRawValue: String // Store enum as string
    var wearLevel: Double // 0.0 to 1.0, affects visual appearance

    // Relationship to messages
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage] = []

    init(title: String, subtitle: String = "", cassetteColor: String = "#8B4513") {
        self.title = title
        self.subtitle = subtitle
        self.createdDate = Date()
        self.lastAccessedDate = Date()
        self.accessCount = 0
        self.cassetteColor = cassetteColor
        self.labelStyleRawValue = (CassetteLabelStyle.allCases.randomElement() ?? .handwritten).rawValue
        self.wearLevel = 0.0
    }

    var labelStyle: CassetteLabelStyle {
        get {
            CassetteLabelStyle(rawValue: labelStyleRawValue) ?? .handwritten
        }
        set {
            labelStyleRawValue = newValue.rawValue
        }
    }
    
    func access() {
        lastAccessedDate = Date()
        accessCount += 1
        // Gradually increase wear with each access
        wearLevel = min(1.0, wearLevel + 0.01)
    }
    
    var isWorn: Bool {
        wearLevel > 0.3
    }
    
    var isVeryWorn: Bool {
        wearLevel > 0.7
    }
}

// MARK: - Cassette Label Styles
enum CassetteLabelStyle: String, CaseIterable, Codable {
    case handwritten = "handwritten"
    case typewriter = "typewriter"
    case marker = "marker"
    case pencil = "pencil"
    
    var font: Font {
        switch self {
        case .handwritten:
            return .custom("Bradley Hand", size: 14)
        case .typewriter:
            return .custom("Courier New", size: 12)
        case .marker:
            return .custom("Marker Felt", size: 14)
        case .pencil:
            return .custom("Noteworthy", size: 13)
        }
    }
    
    var color: Color {
        switch self {
        case .handwritten:
            return Color(red: 0.2, green: 0.2, blue: 0.4)
        case .typewriter:
            return Color.black
        case .marker:
            return Color(red: 0.1, green: 0.1, blue: 0.8)
        case .pencil:
            return Color(red: 0.3, green: 0.3, blue: 0.3)
        }
    }
}

// MARK: - Cassette View Component
struct CassetteView: View {
    let cassette: CassetteMemory
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            ZStack {
                // Cassette body
                HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                    .fill(Color(hex: cassette.cassetteColor))
                    .overlay(
                        // Wear effects
                        Group {
                            if cassette.isWorn {
                                HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                                    .fill(Color.black.opacity(0.1))
                            }
                            if cassette.isVeryWorn {
                                // Scratches and scuffs
                                Path { path in
                                    for _ in 0..<Int(cassette.wearLevel * 10) {
                                        let startX = CGFloat.random(in: 10...90)
                                        let startY = CGFloat.random(in: 10...50)
                                        let endX = startX + CGFloat.random(in: -20...20)
                                        let endY = startY + CGFloat.random(in: -5...5)
                                        
                                        path.move(to: CGPoint(x: startX, y: startY))
                                        path.addLine(to: CGPoint(x: endX, y: endY))
                                    }
                                }
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                            }
                        }
                    )
                    .frame(width: 120, height: 80)
                
                // Cassette holes (reels)
                HStack(spacing: 40) {
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 20, height: 20)
                }
                .offset(y: -10)
                
                // Label area
                VStack(spacing: 2) {
                    Spacer()
                    
                    // White label background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(cassette.isWorn ? 0.8 : 0.95))
                        .frame(width: 100, height: 35)
                        .overlay(
                            VStack(spacing: 1) {
                                Text(cassette.title)
                                    .font(cassette.labelStyle.font)
                                    .foregroundColor(cassette.labelStyle.color)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                if !cassette.subtitle.isEmpty {
                                    Text(cassette.subtitle)
                                        .font(.system(size: 8))
                                        .foregroundColor(cassette.labelStyle.color.opacity(0.7))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                                
                                // Date on label
                                Text(formatDate(cassette.createdDate))
                                    .font(.system(size: 6))
                                    .foregroundColor(cassette.labelStyle.color.opacity(0.5))
                            }
                            .padding(.horizontal, 4)
                        )
                    
                    Spacer()
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(color: .cassetteBrown.opacity(0.3), radius: 4, x: 2, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
