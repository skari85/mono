//
//  DebugAIProviders.swift
//  Mono
//
//  Debug utility for testing AI provider API calls
//

import Foundation
import SwiftUI

class DebugAIProviders {
    static func testAllProviders() async {
        print("🔍 Starting AI Provider Debug Tests...")
        
        let aiManager = AIServiceManager.shared
        let testMessage = ChatMessage(text: "Hello, please respond with 'Test successful'", isUser: true)
        
        for (providerId, provider) in aiManager.availableProviders {
            print("\n📡 Testing \(provider.name) (\(providerId))...")
            
            // Check if provider is configured
            if !provider.isConfigured {
                print("❌ \(provider.name): Not configured (no API key)")
                continue
            }
            
            print("✅ \(provider.name): API key found")
            
            // Test chat completion
            do {
                // Temporarily set this provider as selected
                let originalProvider = aiManager.selectedProvider
                aiManager.selectedProvider = providerId
                
                let response = try await aiManager.sendChatMessage(
                    messages: [testMessage],
                    systemPrompt: "You are a helpful assistant. Respond briefly.",
                    temperature: 0.1
                )
                
                print("✅ \(provider.name): Chat test successful")
                print("📝 Response: \(response.prefix(100))...")
                
                // Restore original provider
                aiManager.selectedProvider = originalProvider
                
            } catch {
                print("❌ \(provider.name): Chat test failed")
                print("🚨 Error: \(error)")
                
                if let aiError = error as? AIServiceError {
                    print("🔍 AI Service Error: \(aiError.errorDescription ?? "Unknown")")
                }
            }
            
            // Test transcription if supported
            if provider.supportedCapabilities.contains(.audioTranscription) {
                print("🎤 Testing transcription for \(provider.name)...")
                // We'll skip actual transcription test for now as it requires audio data
                print("⏭️ Skipping transcription test (requires audio data)")
            }
        }
        
        print("\n🏁 Debug tests completed!")
    }
    
    static func testSpecificProvider(_ providerId: String) async {
        print("🔍 Testing specific provider: \(providerId)")
        
        let aiManager = AIServiceManager.shared
        
        guard let provider = aiManager.availableProviders[providerId] else {
            print("❌ Provider \(providerId) not found")
            return
        }
        
        print("📡 Testing \(provider.name)...")
        
        if !provider.isConfigured {
            print("❌ Provider not configured (no API key)")
            return
        }
        
        // Test with minimal message
        let testMessage = ChatMessage(text: "Hi", isUser: true)
        
        do {
            let originalProvider = aiManager.selectedProvider
            aiManager.selectedProvider = providerId
            
            let response = try await aiManager.sendChatMessage(
                messages: [testMessage],
                systemPrompt: nil,
                temperature: 0.1
            )
            
            print("✅ Success! Response: \(response)")
            aiManager.selectedProvider = originalProvider
            
        } catch {
            print("❌ Failed: \(error)")
            
            if let urlError = error as? URLError {
                print("🌐 URL Error: \(urlError.localizedDescription)")
                print("🔍 Error Code: \(urlError.code.rawValue)")
            }
            
            if let aiError = error as? AIServiceError {
                print("🔍 AI Service Error: \(aiError.errorDescription ?? "Unknown")")
            }
        }
    }
    
    static func debugAPIRequest(for providerId: String) async {
        print("🔍 Debugging API request for: \(providerId)")
        
        let aiManager = AIServiceManager.shared
        
        guard aiManager.availableProviders[providerId] != nil else {
            print("❌ Provider not found")
            return
        }
        
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: providerId) else {
            print("❌ No API key found")
            return
        }
        
        print("✅ API key found: \(String(apiKey.prefix(10)))...")
        
        // Test basic connectivity
        switch providerId {
        case "openai":
            await testOpenAIConnectivity(apiKey: apiKey)
        case "gemini":
            await testGeminiConnectivity(apiKey: apiKey)
        case "groq":
            await testGroqConnectivity(apiKey: apiKey)
        default:
            print("❌ Unknown provider for connectivity test")
        }
    }
    
    private static func testOpenAIConnectivity(apiKey: String) async {
        print("🔍 Testing OpenAI connectivity...")
        
        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("✅ OpenAI API accessible")
                } else {
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    print("❌ OpenAI API error: \(bodyText)")
                }
            }
        } catch {
            print("❌ OpenAI connectivity failed: \(error)")
        }
    }
    
    private static func testGeminiConnectivity(apiKey: String) async {
        print("🔍 Testing Gemini connectivity...")
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)")!
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("✅ Gemini API accessible")
                } else {
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    print("❌ Gemini API error: \(bodyText)")
                }
            }
        } catch {
            print("❌ Gemini connectivity failed: \(error)")
        }
    }
    

    
    private static func testGroqConnectivity(apiKey: String) async {
        print("🔍 Testing Groq connectivity...")
        
        let url = URL(string: "https://api.groq.com/openai/v1/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("✅ Groq API accessible")
                } else {
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    print("❌ Groq API error: \(bodyText)")
                }
            }
        } catch {
            print("❌ Groq connectivity failed: \(error)")
        }
    }
}

// MARK: - Debug View for Testing

struct DebugAIProvidersView: View {
    @State private var testResults: [String] = []
    @State private var isRunning = false

    var body: some View {
        NavigationView {
            VStack {
                if isRunning {
                    ProgressView("Testing AI Providers...")
                        .padding()
                } else {
                    Button("Test All Providers") {
                        testAllProviders()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                List(testResults, id: \.self) { result in
                    Text(result)
                        .font(.caption)
                }
            }
            .navigationTitle("AI Provider Debug")
        }
    }

    private func testAllProviders() {
        isRunning = true
        testResults.removeAll()

        Task {
            await DebugAIProviders.testAllProviders()

            await MainActor.run {
                isRunning = false
                testResults.append("Testing completed. Check console for detailed results.")
            }
        }
    }
}
