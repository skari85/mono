//
//  AIProviderStatusView.swift
//  Mono
//
//  Provider status indicators and error handling UI
//

import SwiftUI

struct AIProviderStatusView: View {
    @EnvironmentObject private var aiServiceManager: AIServiceManager
    @State private var providerStatuses: [String: ProviderStatus] = [:]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(Array(aiServiceManager.availableProviders.keys.sorted()), id: \.self) { providerId in
                        if let provider = aiServiceManager.availableProviders[providerId],
                           let status = providerStatuses[providerId] {
                            ProviderStatusRow(
                                provider: provider,
                                status: status,
                                isSelected: aiServiceManager.selectedProvider == providerId
                            )
                        }
                    }
                } header: {
                    Text("Provider Status")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("Monitor the status of your configured AI service providers.")
                        .foregroundColor(.cassetteTextMedium)
                }
                
                // Current Provider Details
                if let currentProvider = aiServiceManager.currentProvider,
                   let currentStatus = providerStatuses[currentProvider.id] {
                    Section {
                        ProviderDetailsView(provider: currentProvider, status: currentStatus)
                    } header: {
                        Text("Current Provider Details")
                            .foregroundColor(.cassetteTextMedium)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.cassetteWarmGray.opacity(0.1))
            .navigationTitle("Provider Status")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                refreshStatuses()
            }
        }
        .onAppear {
            refreshStatuses()
        }
    }
    
    private func refreshStatuses() {
        providerStatuses = aiServiceManager.getProviderStatus()
    }
}

// MARK: - Provider Status Row

struct ProviderStatusRow: View {
    let provider: AIServiceProvider
    let status: ProviderStatus
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Provider Icon
            Image(systemName: providerIcon)
                .foregroundColor(providerColor)
                .frame(width: 24)
            
            // Provider Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundColor(.cassetteTextDark)
                    
                    if isSelected {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.cassetteOrange.opacity(0.2))
                            )
                            .foregroundColor(.cassetteOrange)
                    }
                }
                
                HStack(spacing: 8) {
                    // Configuration Status
                    StatusBadge(
                        text: status.isConfigured ? "Configured" : "Setup Required",
                        color: status.isConfigured ? .green : .cassetteRed
                    )
                    
                    // Model Count
                    StatusBadge(
                        text: "\(status.modelCount) models",
                        color: .cassetteBlue
                    )
                }
            }
            
            Spacer()
            
            // Overall Status Indicator
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(overallStatusColor)
                    .frame(width: 12, height: 12)
                
                Text(overallStatusText)
                    .font(.caption2)
                    .foregroundColor(.cassetteTextMedium)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var providerIcon: String {
        switch provider.id {
        case "groq": return "bolt.fill"
        case "openai": return "brain.head.profile"
        case "gemini": return "sparkles"
        case "openrouter": return "arrow.triangle.swap"
        default: return "cpu.fill"
        }
    }
    
    private var providerColor: Color {
        switch provider.id {
        case "groq": return .cassetteOrange
        case "openai": return .cassetteBlue
        case "gemini": return .cassetteTeal
        case "openrouter": return .cassetteSage
        default: return .cassetteTextMedium
        }
    }
    
    private var overallStatusColor: Color {
        if status.isConfigured && status.hasValidKey {
            return .green
        } else if status.hasValidKey {
            return .cassetteOrange
        } else {
            return .cassetteRed
        }
    }
    
    private var overallStatusText: String {
        if status.isConfigured && status.hasValidKey {
            return "Ready"
        } else if status.hasValidKey {
            return "Partial"
        } else {
            return "Not Ready"
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.4), lineWidth: 0.5)
            )
            .foregroundColor(color)
    }
}

// MARK: - Provider Details View

struct ProviderDetailsView: View {
    let provider: AIServiceProvider
    let status: ProviderStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Basic Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cassetteTextDark)
                
                Text(provider.description)
                    .font(.body)
                    .foregroundColor(.cassetteTextMedium)
            }
            
            // Capabilities
            VStack(alignment: .leading, spacing: 8) {
                Text("Capabilities")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cassetteTextDark)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(status.supportedCapabilities), id: \.self) { capability in
                        CapabilityChip(capability: capability)
                    }
                }
            }
            
            // Configuration Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Configuration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cassetteTextDark)
                
                VStack(alignment: .leading, spacing: 4) {
                    ConfigurationRow(
                        title: "API Key",
                        isConfigured: status.hasValidKey
                    )
                    
                    ConfigurationRow(
                        title: "Provider Setup",
                        isConfigured: status.isConfigured
                    )
                    
                    ConfigurationRow(
                        title: "Models Available",
                        isConfigured: status.modelCount > 0,
                        detail: "\(status.modelCount) models"
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Configuration Row

struct ConfigurationRow: View {
    let title: String
    let isConfigured: Bool
    let detail: String?
    
    init(title: String, isConfigured: Bool, detail: String? = nil) {
        self.title = title
        self.isConfigured = isConfigured
        self.detail = detail
    }
    
    var body: some View {
        HStack {
            Image(systemName: isConfigured ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isConfigured ? .green : .cassetteRed)
                .frame(width: 16)
            
            Text(title)
                .font(.body)
                .foregroundColor(.cassetteTextDark)
            
            Spacer()
            
            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
            }
        }
    }
}
