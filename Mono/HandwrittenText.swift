//
//  HandwrittenText.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import SwiftUI
import Foundation

// MARK: - Handwritten Text Component
struct HandwrittenText: View {
    let text: String
    let handwritingStyle: HandwritingStyle
    let animateWriting: Bool

    init(text: String, style: HandwritingStyle = .casual, animate: Bool = false) {
        self.text = text
        self.handwritingStyle = style
        self.animateWriting = animate
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Paper background with subtle texture
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    // Paper texture
                    Canvas { context, size in
                        // Guard against invalid dimensions
                        guard size.width > 1 && size.height > 1 &&
                              size.width.isFinite && size.height.isFinite &&
                              size.width < 10000 && size.height < 10000 else {
                            return
                        }
                        
                        let area = size.width * size.height
                        guard area.isFinite && area > 0 else {
                            return
                        }
                        
                        let grainCount = Int(area / 300)
                        for _ in 0..<grainCount {
                            let x = Double.random(in: 0...size.width)
                            let y = Double.random(in: 0...size.height)
                            let opacity = Double.random(in: 0.02...0.06)

                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(.cassetteBrown.opacity(opacity))
                            )
                        }
                    }
                )
                .shadow(color: .cassetteBrown.opacity(0.2), radius: 6, x: 0, y: 4)

            // Handwritten text with natural imperfections
            Text(text)
                .font(handwritingStyle.font)
                .foregroundColor(handwritingStyle.inkColor)
                .lineSpacing(handwritingStyle.lineSpacing)
                .multilineTextAlignment(.leading)
                .padding(20)
                .overlay(
                    // Add some ink blots and imperfections
                    Canvas { context, size in
                        // Random ink spots
                        for _ in 0..<max(1, text.count / 30) {
                            let x = Double.random(in: 20...size.width - 20)
                            let y = Double.random(in: 20...size.height - 20)
                            let radius = Double.random(in: 0.5...1.5)

                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                                with: .color(handwritingStyle.inkColor.opacity(0.3))
                            )
                        }
                    }
                )
        }
    }
}



// MARK: - Handwriting Styles
enum HandwritingStyle: String, CaseIterable {
    case casual = "casual"
    case neat = "neat"
    case hurried = "hurried"
    case careful = "careful"
    
    var font: Font {
        switch self {
        case .casual:
            return .custom("Bradley Hand", size: 16)
        case .neat:
            return .custom("Noteworthy", size: 15)
        case .hurried:
            return .custom("Marker Felt", size: 17)
        case .careful:
            return .custom("Snell Roundhand", size: 14)
        }
    }
    
    var inkColor: Color {
        switch self {
        case .casual:
            return Color(red: 0.2, green: 0.2, blue: 0.8) // Blue ink
        case .neat:
            return Color.black
        case .hurried:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Dark gray
        case .careful:
            return Color(red: 0.0, green: 0.2, blue: 0.4) // Dark blue
        }
    }
    
    var lineSpacing: CGFloat {
        switch self {
        case .casual:
            return 8
        case .neat:
            return 6
        case .hurried:
            return 10
        case .careful:
            return 5
        }
    }
    
    var description: String {
        switch self {
        case .casual:
            return "Relaxed handwriting"
        case .neat:
            return "Careful penmanship"
        case .hurried:
            return "Quick notes"
        case .careful:
            return "Deliberate writing"
        }
    }
}
