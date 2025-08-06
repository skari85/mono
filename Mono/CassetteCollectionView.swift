//
//  CassetteCollectionView.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import SwiftUI
import SwiftData

struct CassetteCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var cassettes: [CassetteMemory]
    
    @State private var showingNewCassetteSheet = false
    @State private var selectedCassette: CassetteMemory?
    
    let columns = [
        GridItem(.adaptive(minimum: 130), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Warm background with texture
                Color.cassetteWarmGray.opacity(0.3)
                    .overlay(PaperTexture(opacity: 0.2))
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        // Add new cassette button
                        Button(action: { showingNewCassetteSheet = true }) {
                            VStack {
                                ZStack {
                                    HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                                        .fill(Color.cassetteBeige.opacity(0.8))
                                        .frame(width: 120, height: 80)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.cassetteOrange)
                                }
                                
                                Text("New Memory")
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                        }
                        
                        // Existing cassettes
                        ForEach(cassettes.sorted(by: { $0.lastAccessedDate > $1.lastAccessedDate })) { cassette in
                            CassetteView(cassette: cassette) {
                                selectedCassette = cassette
                                cassette.access()
                                try? modelContext.save()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Memory Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.cassetteTextDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewCassetteSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.cassetteOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewCassetteSheet) {
            NewCassetteView { title, subtitle, color in
                createNewCassette(title: title, subtitle: subtitle, color: color)
            }
        }
        .sheet(item: $selectedCassette) { cassette in
            CassetteDetailView(cassette: cassette)
        }
    }
    
    private func createNewCassette(title: String, subtitle: String, color: String) {
        let newCassette = CassetteMemory(title: title, subtitle: subtitle, cassetteColor: color)
        modelContext.insert(newCassette)
        try? modelContext.save()
    }
}

// MARK: - New Cassette Creation View
struct NewCassetteView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var subtitle = ""
    @State private var selectedColor = "#8B4513"
    
    let onSave: (String, String, String) -> Void
    
    let cassetteColors = [
        "#8B4513", // Brown
        "#CD853F", // Peru
        "#A0522D", // Sienna
        "#D2691E", // Chocolate
        "#B22222", // Fire Brick
        "#2F4F4F", // Dark Slate Gray
        "#556B2F", // Dark Olive Green
        "#483D8B"  // Dark Slate Blue
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cassetteWarmGray.opacity(0.3)
                    .overlay(PaperTexture(opacity: 0.2))
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Preview
                    VStack {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)
                        
                        CassettePreview(title: title.isEmpty ? "Untitled" : title,
                                      subtitle: subtitle,
                                      color: selectedColor)
                    }
                    
                    // Form
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(.cassetteTextDark)
                            
                            TextField("Memory title...", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subtitle (optional)")
                                .font(.headline)
                                .foregroundColor(.cassetteTextDark)
                            
                            TextField("Additional details...", text: $subtitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cassette Color")
                                .font(.headline)
                                .foregroundColor(.cassetteTextDark)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(cassetteColors, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.cassetteTextDark, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(title, subtitle, selectedColor)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Cassette Preview
struct CassettePreview: View {
    let title: String
    let subtitle: String
    let color: String
    
    var body: some View {
        ZStack {
            // Cassette body
            HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                .fill(Color(hex: color))
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
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 100, height: 35)
                    .overlay(
                        VStack(spacing: 1) {
                            Text(title)
                                .font(.custom("Bradley Hand", size: 14))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            if !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.system(size: 8))
                                    .foregroundColor(.black.opacity(0.7))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            
                            Text(formatDate(Date()))
                                .font(.system(size: 6))
                                .foregroundColor(.black.opacity(0.5))
                        }
                        .padding(.horizontal, 4)
                    )
                
                Spacer()
            }
        }
        .shadow(color: .cassetteBrown.opacity(0.3), radius: 4, x: 2, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}
