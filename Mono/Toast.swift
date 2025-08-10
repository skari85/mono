//  Toast.swift
//  Mono
//
//  Lightweight toast/banner component
//

import SwiftUI

struct Toast: View {
    let message: String
    let isError: Bool
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(isError ? .red : .cassetteTeal)
            Text(message)
                .font(.caption)
                .foregroundColor(.cassetteTextDark)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if let actionTitle {
                Button(actionTitle) {
                    action?()
                }
                .font(.caption.bold())
                .foregroundColor(.cassetteTeal)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 2.5)
                .fill((isError ? Color.red.opacity(0.12) : Color.cassetteTeal.opacity(0.12)))
        )
        .overlay(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 2.5)
                .stroke(isError ? Color.red.opacity(0.3) : Color.cassetteTeal.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

