# Mono - Minimalist AI Chat App

A beautiful, minimalist AI chat application built with SwiftUI and SwiftData. Mono provides a clean, distraction-free interface for conversing with AI.

## Features

### 🧠 Personality Modes
- **Smart**: Thoughtful, well-structured responses
- **Quiet**: Concise and peaceful interactions  
- **Play**: Playful and creative responses

Tap the mode name at the top to cycle through personalities.

### 💬 Core Features
- **Single Screen Design**: Clean, focused chat interface
- **Quick Prompts**: Tap the "+" button for instant conversation starters
- **Response Enhancers**: Tap any AI message to see quick actions:
  - 🔁 Regenerate
  - ✂️ Make shorter
  - 🌱 Expand idea
  - 🤯 Surprise me

### 🤖 Multi-Provider AI Support
- **Provider Choice**: Switch between Groq, OpenAI, and Gemini
- **Model Selection**: Choose from available models for each provider
- **Secure Storage**: API keys stored safely in iOS Keychain
- **Provider Status**: Monitor configuration and availability of each service
- **Unified Interface**: Consistent experience across all AI providers

### 🎨 Design
- Minimalist top bar with personality mode toggle
- Modern message bubbles with smooth animations
- Bottom input with mic and quick prompts
- Settings accessible via "..." menu
- Vintage cassette-inspired color palette and textures

## Setup

1. **Choose Your AI Provider**: Mono supports multiple AI service providers:
   - **Groq** - Fast inference with Llama models
   - **OpenAI** - GPT models including GPT-4o and GPT-3.5 Turbo
   - **Google Gemini** - Advanced AI models with large context windows

2. **Get an API Key**: Visit your chosen provider's website to get an API key:
   - [Groq Console](https://console.groq.com/keys)
   - [OpenAI Platform](https://platform.openai.com/api-keys)
   - [Google AI Studio](https://aistudio.google.com/app/apikey)

3. **Configure the App**:
   - Open Settings (tap "..." in top right)
   - Tap "AI Provider" to select and configure your preferred service
   - Enter your API key securely
   - Choose your preferred model

4. **Start Chatting**: Begin typing or use quick prompts to start conversations

## Privacy & Data

🔐 **Privacy First Design**
- **100% Local Storage**: All your conversations, thoughts, and data stay on your device
- **No Analytics**: Zero tracking, telemetry, or data collection
- **iCloud Sync Only**: Optional backup through your personal iCloud (you control this)
- **Your Keys**: Bring your own API keys - we never see your data
- **Open Source**: Full transparency in how your data is handled

## Technical Details

- **Framework**: SwiftUI + Local Storage (JSON)
- **AI Providers**: Multi-provider BYOK (Bring Your Own Key) system
- **Data Storage**: Local files with optional iCloud sync
- **Security**: API keys stored in iOS Keychain
- **Supported Services**: Groq, OpenAI, Google Gemini
- **Platform**: iOS 17.0+

## Architecture

### Core Components
- `ContentView`: Main chat interface with vintage cassette aesthetic
- `ChatViewModel`: Business logic and AI service communication
- `ChatMessage`: SwiftData model for message persistence
- `PersonalityMode`: Enum for different AI personalities

### AI Service System
- `AIServiceManager`: Central coordinator for multiple AI providers
- `AIServiceProvider`: Protocol defining common interface for all providers
- `APIKeyManager`: Secure storage and management of API keys using iOS Keychain
- Provider implementations: `GroqServiceProvider`, `OpenAIServiceProvider`, `GeminiServiceProvider`

### Technical Stack
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Core Data successor for local persistence
- **MVVM Pattern**: Clean separation of concerns
- **Combine**: Reactive programming for state management
- **Protocol-Based Design**: Extensible provider system for easy integration of new AI services

## Future Enhancements

- [ ] Voice input support
- [ ] Message search and history
- [ ] Custom personality creation
- [ ] Export conversations
- [ ] Dark mode optimizations
- [ ] iCloud sync for settings

---

Built with ❤️ using SwiftUI 