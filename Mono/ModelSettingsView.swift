//  ModelSettingsView.swift
//  Mono
//
//  Enhanced model selection with multi-provider support
//

import SwiftUI

struct ModelSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var aiServiceManager: AIServiceManager

    var body: some View {
        List {
            // Provider & Model Overview
            if let currentProvider = aiServiceManager.currentProvider {
                Section {
                    VStack(spacing: 12) {
                        // Provider info
                        HStack {
                            Image(systemName: providerIcon(for: currentProvider.id))
                                .foregroundColor(providerColor(for: currentProvider.id))
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentProvider.name)
                                    .font(.headline)
                                    .foregroundColor(.cassetteTextDark)

                                Text("Active Provider • \(currentProvider.availableModels.count) models")
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }

                            Spacer()

                            NavigationLink(destination: AIProviderSettingsView()) {
                                Text("Switch")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.cassetteTeal.opacity(0.1))
                                    )
                                    .foregroundColor(.cassetteTeal)
                            }
                        }

                        // Current model display
                        HStack {
                            Text("Current Model:")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)

                            Text(settingsManager.llmModel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.cassetteTextDark)

                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("AI Configuration")
                        .foregroundColor(.cassetteTextMedium)
                }

                // Chat Models Section
                let chatModels = currentProvider.availableModels.filter {
                    $0.capabilities.contains(.chatCompletion)
                }

                if !chatModels.isEmpty {
                    Section {
                        ForEach(chatModels) { model in
                            ModelRow(
                                model: model,
                                isSelected: getSelectedModel(for: currentProvider.id) == model.id,
                                onSelect: {
                                    aiServiceManager.setSelectedModel(model.id, for: currentProvider.id)
                                }
                            )
                        }
                    } header: {
                        Text("Chat Models")
                            .foregroundColor(.cassetteTextMedium)
                    } footer: {
                        Text("Choose the model that best fits your needs. Higher quality models may be slower or more expensive.")
                            .foregroundColor(.cassetteTextMedium)
                    }
                }

                // Transcription Models Section
                let transcriptionModels = currentProvider.availableModels.filter {
                    $0.capabilities.contains(.audioTranscription)
                }

                // Voice & Transcription Settings - Consolidated
                Section {
                    // Transcription models (if available)
                    if !transcriptionModels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Transcription")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.cassetteTextDark)

                            ForEach(transcriptionModels.prefix(3)) { model in
                                ModelRow(
                                    model: model,
                                    isSelected: getSelectedTranscriptionModel(for: currentProvider.id) == model.id,
                                    onSelect: {
                                        aiServiceManager.setSelectedTranscriptionModel(model.id, for: currentProvider.id)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Language setting
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.cassetteBlue)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language")
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextDark)

                            Text(settingsManager.transcriptionLanguage == "auto" ? "Auto-detect" : settingsManager.transcriptionLanguage.uppercased())
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }

                        Spacer()

                        NavigationLink(destination: TranscriptionSettingsView()) {
                            Text("Change")
                                .font(.caption)
                                .foregroundColor(.cassetteTeal)
                        }
                    }
                } header: {
                    Text("Voice & Transcription")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("Configure voice recording transcription settings. Some providers offer better transcription models.")
                        .foregroundColor(.cassetteTextMedium)
                }
            } else {
                // No Provider Selected
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.cassetteOrange)

                        Text("No AI Provider Selected")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        Text("Please configure an AI service provider to select models.")
                            .font(.body)
                            .foregroundColor(.cassetteTextMedium)
                            .multilineTextAlignment(.center)

                        NavigationLink(destination: AIProviderSettingsView()) {
                            Text("Configure Provider")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 2.0)
                                        .fill(Color.cassetteOrange)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.cassetteWarmGray.opacity(0.1))
        .navigationTitle("AI Models")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Helper Methods

    private func getSelectedModel(for providerId: String) -> String {
        let key = "selected_model_\(providerId)"
        return UserDefaults.standard.string(forKey: key) ??
               aiServiceManager.availableProviders[providerId]?.availableModels.first?.id ?? ""
    }

    private func getSelectedTranscriptionModel(for providerId: String) -> String? {
        let key = "selected_transcription_model_\(providerId)"
        return UserDefaults.standard.string(forKey: key) ??
               aiServiceManager.availableProviders[providerId]?.availableModels.first(where: {
                   $0.capabilities.contains(.audioTranscription)
               })?.id
    }

    private func providerIcon(for providerId: String) -> String {
        switch providerId {
        case "groq": return "bolt.fill"
        case "openai": return "brain.head.profile"
        case "gemini": return "sparkles"
        default: return "cpu.fill"
        }
    }

    private func providerColor(for providerId: String) -> Color {
        switch providerId {
        case "groq": return .cassetteOrange
        case "openai": return .cassetteBlue
        case "gemini": return .cassetteTeal
        default: return .cassetteTextMedium
        }
    }
}

// MARK: - Model Row

struct ModelRow: View {
    let model: AIModel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.cassetteTextDark)
                        .multilineTextAlignment(.leading)

                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.cassetteTextMedium)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        // Cost tier indicator
                        CostTierChip(tier: model.costTier)

                        // Context window if available
                        if let contextWindow = model.contextWindow {
                            ContextWindowChip(tokens: contextWindow)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cassetteOrange)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cost Tier Chip

struct CostTierChip: View {
    let tier: AIModel.CostTier

    var body: some View {
        Text(tierName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(tierColor.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(tierColor.opacity(0.4), lineWidth: 0.5)
            )
            .foregroundColor(tierColor)
    }

    private var tierName: String {
        switch tier {
        case .free: return "Free"
        case .low: return "Low Cost"
        case .medium: return "Medium"
        case .high: return "High Cost"
        case .premium: return "Premium"
        }
    }

    private var tierColor: Color {
        switch tier {
        case .free: return .green
        case .low: return .cassetteTeal
        case .medium: return .cassetteOrange
        case .high: return .cassetteRed
        case .premium: return .cassetteBrown
        }
    }
}

// MARK: - Context Window Chip

struct ContextWindowChip: View {
    let tokens: Int

    var body: some View {
        Text("\(formattedTokens) context")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.cassetteBlue.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(Color.cassetteBlue.opacity(0.3), lineWidth: 0.5)
            )
            .foregroundColor(.cassetteBlue)
    }

    private var formattedTokens: String {
        if tokens >= 1000000 {
            return "\(tokens / 1000000)M"
        } else if tokens >= 1000 {
            return "\(tokens / 1000)K"
        } else {
            return "\(tokens)"
        }
    }
}

