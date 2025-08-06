//
//  CassetteDetailView.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import SwiftUI
import SwiftData
import AVFoundation

struct CassetteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let cassette: CassetteMemory
    
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0.0
    @State private var currentMessageIndex = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Vintage background
                Color.cassetteWarmGray.opacity(0.3)
                    .overlay(PaperTexture(opacity: 0.3))
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Cassette Display
                    VStack(spacing: 16) {
                        CassetteView(cassette: cassette) {
                            // Tap to play/pause
                            togglePlayback()
                        }
                        
                        // Cassette Info
                        VStack(spacing: 8) {
                            Text(cassette.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.cassetteTextDark)
                            
                            if !cassette.subtitle.isEmpty {
                                Text(cassette.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                            
                            HStack(spacing: 16) {
                                Label("\(cassette.messages.count) messages", systemImage: "message")
                                Label("Played \(cassette.accessCount) times", systemImage: "play")
                            }
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)
                        }
                    }
                    
                    // Cassette Player Controls
                    VStack(spacing: 16) {
                        // Progress bar (tape reel simulation)
                        HStack {
                            // Left reel
                            Circle()
                                .fill(Color.cassetteDarkGray)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .fill(Color.cassetteBrown)
                                        .frame(width: CGFloat(30 - playbackProgress * 10))
                                        .rotationEffect(.degrees(isPlaying ? 360 : 0))
                                        .animation(isPlaying ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isPlaying)
                                )
                            
                            // Tape line
                            Rectangle()
                                .fill(Color.cassetteBrown.opacity(0.6))
                                .frame(height: 2)
                                .overlay(
                                    Rectangle()
                                        .fill(Color.cassetteBrown)
                                        .frame(width: CGFloat(playbackProgress * 200), height: 2)
                                        .animation(.easeInOut(duration: 0.3), value: playbackProgress),
                                    alignment: .leading
                                )
                            
                            // Right reel
                            Circle()
                                .fill(Color.cassetteDarkGray)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .fill(Color.cassetteBrown)
                                        .frame(width: CGFloat(20 + playbackProgress * 10))
                                        .rotationEffect(.degrees(isPlaying ? -360 : 0))
                                        .animation(isPlaying ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isPlaying)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Control buttons
                        HStack(spacing: 32) {
                            Button(action: previousMessage) {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                                    .foregroundColor(.cassetteTextDark)
                            }
                            .disabled(currentMessageIndex <= 0)
                            
                            Button(action: togglePlayback) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.cassetteOrange)
                            }
                            .disabled(cassette.messages.isEmpty)
                            
                            Button(action: nextMessage) {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                                    .foregroundColor(.cassetteTextDark)
                            }
                            .disabled(currentMessageIndex >= cassette.messages.count - 1)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        HandDrawnRoundedRectangle(cornerRadius: 16, roughness: 4.0)
                            .fill(Color.cassetteBeige.opacity(0.8))
                    )
                    .padding(.horizontal, 20)
                    
                    // Current message display
                    if !cassette.messages.isEmpty && currentMessageIndex < cassette.messages.count {
                        let currentMessage = sortedMessages[currentMessageIndex]
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(currentMessage.isUser ? "You" : "Mono")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.cassetteTextMedium)
                                    
                                    Spacer()
                                    
                                    Text(formatTimestamp(currentMessage.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.cassetteTextMedium.opacity(0.7))
                                }
                                
                                if currentMessage.isHandwritten && !currentMessage.isUser {
                                    HandwrittenText(
                                        text: currentMessage.text,
                                        style: currentMessage.handwritingStyleEnum,
                                        animate: isPlaying
                                    )
                                } else {
                                    Text(currentMessage.text)
                                        .font(.body)
                                        .foregroundColor(.cassetteTextDark)
                                        .padding(16)
                                        .background(
                                            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 3.0)
                                                .fill(currentMessage.isUser ? Color.cassetteOrange.opacity(0.3) : Color.cassetteBeige)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "message.badge")
                                .font(.largeTitle)
                                .foregroundColor(.cassetteTextMedium.opacity(0.5))
                            
                            Text("This cassette is empty")
                                .font(.headline)
                                .foregroundColor(.cassetteTextMedium)
                            
                            Text("Start a conversation to record memories on this cassette")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Memory Playback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        stopPlayback()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.cassetteRed)
                }
            }
        }
        .alert("Delete Memory", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCassette()
            }
        } message: {
            Text("This will permanently delete this memory cassette and all its conversations.")
        }
        .onAppear {
            setupAudioSession()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private var sortedMessages: [ChatMessage] {
        cassette.messages.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard !cassette.messages.isEmpty else { return }
        
        isPlaying = true
        playTapeSound()
        
        // Simulate playback progress
        withAnimation(.linear(duration: 3.0)) {
            playbackProgress = Double(currentMessageIndex + 1) / Double(cassette.messages.count)
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        audioPlayer?.stop()
    }
    
    private func nextMessage() {
        if currentMessageIndex < cassette.messages.count - 1 {
            currentMessageIndex += 1
            updatePlaybackProgress()
        }
    }
    
    private func previousMessage() {
        if currentMessageIndex > 0 {
            currentMessageIndex -= 1
            updatePlaybackProgress()
        }
    }
    
    private func updatePlaybackProgress() {
        withAnimation(.easeInOut(duration: 0.3)) {
            playbackProgress = Double(currentMessageIndex + 1) / Double(cassette.messages.count)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func playTapeSound() {
        // Play subtle tape hiss sound (would need audio file)
        // For now, just haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func deleteCassette() {
        modelContext.delete(cassette)
        try? modelContext.save()
        dismiss()
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
