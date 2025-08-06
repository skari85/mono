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

### 🎨 Design
- Minimalist top bar with personality mode toggle
- Modern message bubbles with smooth animations
- Bottom input with mic and quick prompts
- Settings accessible via "..." menu

## Setup

1. **Get a Groq API Key**: Visit [groq.com](https://groq.com) to get your API key
2. **Configure the App**: Open Settings (tap "..." in top right) and enter your API key
3. **Start Chatting**: Begin typing or use quick prompts to start conversations

## Technical Details

- **Framework**: SwiftUI + SwiftData
- **AI Provider**: Groq API (Llama 3.1 70B)
- **Storage**: Local SwiftData persistence
- **Platform**: iOS 17.0+

## Architecture

- `ContentView`: Main chat interface
- `ChatViewModel`: Business logic and API communication
- `ChatMessage`: SwiftData model for message persistence
- `PersonalityMode`: Enum for different AI personalities

## Future Enhancements

- [ ] Voice input support
- [ ] Message search and history
- [ ] Custom personality creation
- [ ] Export conversations
- [ ] Dark mode optimizations
- [ ] iCloud sync for settings

---

Built with ❤️ using SwiftUI 