//  TranscriptionSettingsView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI

struct TranscriptionSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    private let languages: [(id: String, label: String)] = [
        ("auto", "Auto-detect (recommended)"),
        ("en", "English"),
        ("de", "German"),
        ("es", "Spanish"),
        ("fr", "French")
    ]

    var body: some View {
        List {
            Section(header: Text("Whisper Language").foregroundColor(.cassetteTextMedium), footer: Text("If you often speak one language, choose it for slightly faster, more accurate transcriptions. Otherwise, keep Auto-detect.").foregroundColor(.cassetteTextMedium)) {
                ForEach(languages, id: \.id) { lang in
                    Button(action: { settingsManager.transcriptionLanguage = lang.id }) {
                        HStack {
                            Text(lang.label)
                                .foregroundColor(.cassetteTextDark)
                            Spacer()
                            if settingsManager.transcriptionLanguage == lang.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cassetteOrange)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Transcription")
        .navigationBarTitleDisplayMode(.large)
    }
}

