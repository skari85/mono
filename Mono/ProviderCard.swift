//
//  ProviderCard.swift
//  Mono
//
//  Provider card component for AI service configuration
//

import SwiftUI

struct ProviderCard: View {
    let provider: AIServiceProvider
    let icon: String
    let color: Color
    let onConfigureKey: () -> Void
    @EnvironmentObject private var aiServiceManager: AIServiceManager

    private var isSelected: Bool {
        aiServiceManager.selectedProvider == provider.id
    }

    var body: some View {
        VStack(spacing: 12) {
            // Provider header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundColor(.cassetteTextDark)
                    
                    Text("\(provider.availableModels.count) models")
                        .font(.caption2)
                        .foregroundColor(.cassetteTextMedium)
                }
                
                Spacer()
                
                // Status indicator with selection state
                VStack(spacing: 4) {
                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(color)
                                .font(.caption)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(color)
                        }
                    }
                    
                    Circle()
                        .fill(provider.isConfigured ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Provider selection button
            if provider.isConfigured {
                Button(action: selectProvider) {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? color : .cassetteTextMedium)
                        
                        Text(isSelected ? "Current Provider" : "Select Provider")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? color : .cassetteTextMedium)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // API Key configuration button
            Button(action: onConfigureKey) {
                HStack {
                    Image(systemName: provider.isConfigured ? "key.fill" : "key")
                        .foregroundColor(provider.isConfigured ? .green : color)
                    
                    Text(provider.isConfigured ? "Edit API Key" : "Add API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(provider.isConfigured ? .green : color)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.cassetteTextMedium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(provider.isConfigured ? Color.green.opacity(0.1) : color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(provider.isConfigured ? Color.green.opacity(0.3) : color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .cassetteBrown.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Private Methods
    
    private func selectProvider() {
        guard provider.isConfigured else { return }
        aiServiceManager.selectedProvider = provider.id
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}
