//  WhisperModelSettingsView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI

struct WhisperModelSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    private let models: [(id: String, label: String)] = [
        ("whisper-large-v3-turbo", "Whisper large v3 Turbo"),
        ("whisper-large-v3", "Whisper large v3")
    ]

    var body: some View {
        List {
            Section(header: Text("Whisper Model").foregroundColor(.cassetteTextMedium)) {
                ForEach(models, id: \.id) { model in
                    Button(action: { settingsManager.whisperModel = model.id }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.label)
                                    .foregroundColor(.cassetteTextDark)
                                Text(model.id)
                                    .font(.caption2)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                            Spacer()
                            if settingsManager.whisperModel == model.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cassetteOrange)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Whisper Model")
        .navigationBarTitleDisplayMode(.large)
    }
}

