//  ModelSettingsView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI

struct ModelSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    private let models: [(id: String, label: String)] = [
        ("llama-3.1-8b-instant", "Llama 3.1 8B (Instant)"),
        ("llama-3.1-70b", "Llama 3.1 70B (Quality)")
    ]

    var body: some View {
        List {
            Section(header: Text("Chat Model").foregroundColor(.cassetteTextMedium)) {
                ForEach(models, id: \.id) { model in
                    Button(action: { settingsManager.llmModel = model.id }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.label)
                                    .foregroundColor(.cassetteTextDark)
                                Text(model.id)
                                    .font(.caption2)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                            Spacer()
                            if settingsManager.llmModel == model.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cassetteOrange)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("AI Model")
        .navigationBarTitleDisplayMode(.large)
    }
}

