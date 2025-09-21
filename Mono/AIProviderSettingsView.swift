//
//  AIProviderSettingsView.swift
//  Mono
//
//  AI service provider selection and configuration UI
//

import SwiftUI

struct AIProviderSettingsView: View {
    @EnvironmentObject private var aiServiceManager: AIServiceManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAPIKeySheet = false
    @State private var selectedProviderForKeyEntry: String?
    
    var body: some View {
        NavigationView {
            List {
                // Quick Setup Section - Most important
                Section {
                    VStack(spacing: 16) {
                        // Header with current status
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.cassetteOrange)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Service Setup")
                                    .font(.headline)
                                    .foregroundColor(.cassetteTextDark)

                                let configuredCount = aiServiceManager.getConfiguredProviders().count
                                let totalCount = aiServiceManager.availableProviders.count
                                Text("\(configuredCount) of \(totalCount) providers configured")
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }

                            Spacer()
                        }

                        // Provider cards grid - Groq and OpenAI
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            // Groq Provider Card
                            if let groqProvider = aiServiceManager.availableProviders["groq"] {
                                ProviderCard(
                                    provider: groqProvider,
                                    icon: "bolt.fill",
                                    color: .cassetteOrange,
                                    onConfigureKey: {
                                        selectedProviderForKeyEntry = "groq"
                                        showingAPIKeySheet = true
                                    }
                                )
                            }
                            
                            // OpenAI Provider Card
                            if let openAIProvider = aiServiceManager.availableProviders["openai"] {
                                ProviderCard(
                                    provider: openAIProvider,
                                    icon: "brain.head.profile",
                                    color: .cassetteBlue,
                                    onConfigureKey: {
                                        selectedProviderForKeyEntry = "openai"
                                        showingAPIKeySheet = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("AI Configuration")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("Configure your API keys for Groq or OpenAI to start using AI features. Keys are stored securely in the device keychain.")
                        .foregroundColor(.cassetteTextMedium)
                }
                
                // Current Selection Info - Compact
                if let currentProvider = aiServiceManager.currentProvider {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active: \(currentProvider.name)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.cassetteTextDark)

                                Text("\(currentProvider.availableModels.count) models • \(currentProvider.supportedCapabilities.count) capabilities")
                                    .font(.caption2)
                                    .foregroundColor(.cassetteTextMedium)
                            }

                            Spacer()

                            // Status indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(currentProvider.isConfigured ? Color.green : Color.cassetteRed)
                                    .frame(width: 8, height: 8)

                                Text(currentProvider.isConfigured ? "Ready" : "Setup Required")
                                    .font(.caption2)
                                    .foregroundColor(currentProvider.isConfigured ? .green : .cassetteRed)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Current Selection")
                            .foregroundColor(.cassetteTextMedium)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.cassetteWarmGray.opacity(0.1))
            .navigationTitle("AI Providers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cassetteOrange)
                }
            }
        }
        .sheet(isPresented: $showingAPIKeySheet) {
            if let providerId = selectedProviderForKeyEntry,
               let provider = aiServiceManager.availableProviders[providerId] {
                APIKeyEntryView(provider: provider)
            } else {
                Text("Error: Provider not found")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

// MARK: - Provider Row

struct ProviderRow: View {
    let provider: AIServiceProvider
    let isSelected: Bool
    let onSelect: () -> Void
    let onConfigureKey: () -> Void
    @EnvironmentObject private var aiServiceManager: AIServiceManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Provider Icon
                Image(systemName: providerIcon)
                    .foregroundColor(providerColor)
                    .frame(width: 24)
                
                // Provider Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundColor(.cassetteTextDark)
                    
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.cassetteTextMedium)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status and Selection
                VStack(alignment: .trailing, spacing: 4) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.cassetteOrange)
                            .font(.title3)
                    }
                    
                    StatusIndicator(isConfigured: aiServiceManager.isProviderConfigured(provider.id))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onConfigureKey) {
                Label("Configure API Key", systemImage: "key.fill")
            }
        }
    }
    
    private var providerIcon: String {
        switch provider.id {
        case "groq": return "bolt.fill"
        case "openai": return "brain.head.profile"
        case "gemini": return "sparkles"
        default: return "cpu.fill"
        }
    }

    private var providerColor: Color {
        switch provider.id {
        case "groq": return .cassetteOrange
        case "openai": return .cassetteBlue
        case "gemini": return .cassetteTeal
        default: return .cassetteTextMedium
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let isConfigured: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConfigured ? Color.green : Color.cassetteRed)
                .frame(width: 8, height: 8)
            
            Text(isConfigured ? "Ready" : "Setup Required")
                .font(.caption2)
                .foregroundColor(isConfigured ? .green : .cassetteRed)
        }
    }
}

// MARK: - Capability Chip

struct CapabilityChip: View {
    let capability: AICapability
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: capabilityIcon)
                .font(.caption2)
            
            Text(capabilityName)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.cassetteTeal.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(Color.cassetteTeal.opacity(0.3), lineWidth: 0.5)
        )
        .foregroundColor(.cassetteTeal)
    }
    
    private var capabilityIcon: String {
        switch capability {
        case .chatCompletion: return "message.fill"
        case .audioTranscription: return "waveform"
        case .textSummarization: return "doc.text.fill"
        }
    }
    
    private var capabilityName: String {
        switch capability {
        case .chatCompletion: return "Chat"
        case .audioTranscription: return "Transcription"
        case .textSummarization: return "Summary"
        }
    }
}

// MARK: - Compact Provider Card

struct CompactProviderCard: View {
    let provider: AIServiceProvider
    let isSelected: Bool
    let onSelect: () -> Void
    let onConfigureKey: () -> Void
    @EnvironmentObject private var aiServiceManager: AIServiceManager

    var body: some View {
        VStack(spacing: 8) {
            // Provider header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: providerIcon)
                            .font(.caption)
                            .foregroundColor(providerColor)
                        Text(provider.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.cassetteTextDark)
                    }

                    Text("\(provider.availableModels.count) models • \(provider.id)")
                        .font(.caption2)
                        .foregroundColor(.cassetteTextMedium)
                }

                Spacer()

                // API Key button - Enhanced for clarity
                Button(action: {
                    print("🔑 Button tapped for provider: \(provider.id) - \(provider.name)")
                    onConfigureKey()
                }) {
                    let isConfigured = aiServiceManager.isProviderConfigured(provider.id)
                    VStack(spacing: 2) {
                        Image(systemName: isConfigured ? "key.fill" : "key")
                            .font(.caption)
                            .foregroundColor(isConfigured ? .green : .cassetteOrange)
                        Text(isConfigured ? "Edit" : "Add")
                            .font(.caption2)
                            .foregroundColor(isConfigured ? .green : .cassetteOrange)
                    }
                    .frame(width: 50, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isConfigured ? Color.green.opacity(0.3) : Color.cassetteOrange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Selection button
            Button(action: onSelect) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .cassetteOrange : .cassetteTextMedium)

                    Text(isSelected ? "Selected" : "Select")
                        .font(.caption)
                        .foregroundColor(isSelected ? .cassetteOrange : .cassetteTextMedium)

                    Spacer()

                    // Status dot
                    let isConfigured = aiServiceManager.isProviderConfigured(provider.id)
                    Circle()
                        .fill(isConfigured ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.cassetteOrange.opacity(0.1) : Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.cassetteOrange.opacity(0.3) : Color.clear, lineWidth: 1)
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
                .stroke(isSelected ? Color.cassetteOrange.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
    
    // MARK: - Provider-specific Properties
    
    private var providerIcon: String {
        switch provider.id {
        case "groq": return "bolt.fill"
        case "openai": return "brain.head.profile"
        case "gemini": return "sparkles"
        default: return "cpu.fill"
        }
    }

    private var providerColor: Color {
        switch provider.id {
        case "groq": return .cassetteOrange
        case "openai": return .cassetteBlue
        case "gemini": return .cassetteTeal
        default: return .cassetteTextMedium
        }
    }
}
