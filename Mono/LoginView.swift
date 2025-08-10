//  LoginView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var onSuccess: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Sign in to Mono")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("Email", text: $email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: signIn) {
                    if isLoading { ProgressView() } else { Text("Sign In").bold() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cassetteOrange)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Login")
        }
    }

    private func signIn() {
        error = nil
        isLoading = true
        // Local-only mock authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            if email.contains("@") && password.count >= 4 {
                UserDefaults.standard.set(true, forKey: "is_authenticated")
                onSuccess()
            } else {
                error = "Invalid credentials."
            }
        }
    }
}

