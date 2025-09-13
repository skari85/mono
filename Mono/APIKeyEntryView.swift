//
//  APIKeyEntryView.swift
//  Mono
//
//  API key entry and management UI
//

import SwiftUI

struct APIKeyEntryView: View {
    let provider: AIServiceProvider
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var apiKey: String = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    private let apiKeyManager = APIKeyManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.cassetteWarmGray.opacity(0.3)
                    .overlay(PaperTexture(opacity: 0.2, seed: 0xABCDEF03))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: providerIcon)
                                .font(.system(size: 48))
                                .foregroundColor(providerColor)
                            
                            VStack(spacing: 8) {
                                Text("Configure \(provider.name)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.cassetteTextDark)
                                
                                Text("Enter your API key to start using \(provider.name)")
                                    .font(.body)
                                    .foregroundColor(.cassetteTextMedium)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // API Key Input
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("API Key")
                                    .font(.headline)
                                    .foregroundColor(.cassetteTextDark)
                                
                                SecureField("Enter your \(provider.name) API key", text: $apiKey)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            // Get API Key Button
                            Button(action: openProviderWebsite) {
                                HStack(spacing: 8) {
                                    Image(systemName: "link")
                                        .font(.caption)
                                    
                                    Text("Get API Key from \(provider.name)")
                                        .font(.body)
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.cassetteTeal)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 2.0)
                                        .stroke(Color.cassetteTeal.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Security Information
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.cassetteTeal)
                                    .frame(width: 24)
                                
                                Text("Security & Privacy")
                                    .font(.headline)
                                    .foregroundColor(.cassetteTextDark)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                SecurityPoint(
                                    icon: "lock.fill",
                                    text: "Your API key is stored securely in the device keychain"
                                )
                                
                                SecurityPoint(
                                    icon: "eye.slash.fill",
                                    text: "Keys are never shared or transmitted to third parties"
                                )
                                
                                SecurityPoint(
                                    icon: "arrow.right.circle.fill",
                                    text: "Direct communication with \(provider.name) servers only"
                                )
                            }
                        }
                        .padding(16)
                        .background(
                            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 3.0)
                                .fill(Color.cassetteTeal.opacity(0.08))
                        )
                        .overlay(
                            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 3.0)
                                .stroke(Color.cassetteTeal.opacity(0.2), lineWidth: 1)
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cassetteTextMedium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveAPIKey) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.cassetteOrange)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(apiKey.isEmpty ? .cassetteTextMedium : .cassetteOrange)
                        }
                    }
                    .disabled(apiKey.isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            loadExistingKey()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("API key saved successfully!")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadExistingKey() {
        if let existingKey = apiKeyManager.getAPIKey(for: provider.id) {
            apiKey = existingKey
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try apiKeyManager.setAPIKey(apiKey, for: provider.id)
                
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func openProviderWebsite() {
        if let url = URL(string: providerWebsiteURL) {
            openURL(url)
        }
    }
    
    // MARK: - Provider-specific Properties
    
    private var providerIcon: String {
        switch provider.id {
        case "groq": return "bolt.fill"
        case "openai": return "brain.head.profile"
        case "gemini": return "sparkles"
        case "openrouter": return "arrow.triangle.swap"
        default: return "key.fill"
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
    
    private var providerWebsiteURL: String {
        switch provider.id {
        case "groq": return "https://console.groq.com/keys"
        case "openai": return "https://platform.openai.com/api-keys"
        case "gemini": return "https://aistudio.google.com/app/apikey"
        case "openrouter": return "https://openrouter.ai/keys"
        default: return "https://example.com"
        }
    }
}

// MARK: - Security Point

struct SecurityPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.cassetteTeal)
                .frame(width: 16)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.cassetteTextMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 2.0)
                    .fill(Color.white.opacity(0.8))
            )
            .overlay(
                HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 2.0)
                    .stroke(Color.cassetteTextMedium.opacity(0.3), lineWidth: 1)
            )
    }
}
