//  LoginView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var onSuccess: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top section with vintage branding
                    VStack(spacing: 32) {
                        Spacer(minLength: 60)

                        // Vintage Mono Logo
                        VStack(spacing: 16) {
                            // Cassette tape icon with gradient
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.cassetteOrange, .cassetteRed],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .cassetteBrown.opacity(0.3), radius: 8, x: 0, y: 4)

                                Text("🎧")
                                    .font(.system(size: 40))
                            }

                            // Colorful Mono branding
                            HStack(spacing: 4) {
                                Text("M").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundColor(.cassetteTextDark)
                                Text("o").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundColor(.cassetteOrange)
                                Text("n").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundColor(.cassetteTextDark)
                                Text("o").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundColor(.cassetteTeal)
                            }

                            Text("Minimalist AI Chat")
                                .font(.headline)
                                .foregroundColor(.cassetteTextMedium)
                        }

                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: geometry.size.height * 0.5)
                    .background(
                        ZStack {
                            Color.cassetteCream
                            PaperTexture(opacity: 0.3, seed: 0xC0FFEECAFE)
                        }
                    )

                    // Bottom section with login options
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            Text("Welcome back")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.cassetteTextDark)

                            // Apple Sign In
                            SignInWithAppleButton(.signIn) { request in
                                // Configure Apple Sign In request
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(12)

                            // Google Sign In Button
                            Button(action: handleGoogleSignIn) {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .font(.title2)
                                    Text("Continue with Google")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }


                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.cassetteTextMedium.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                                    .padding(.horizontal, 16)
                                Rectangle()
                                    .fill(Color.cassetteTextMedium.opacity(0.3))
                                    .frame(height: 1)
                            }

                            // Email/Password Form
                            VStack(spacing: 16) {
                                TextField("Email", text: $email)
                                    .textContentType(.username)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.cassetteBeige.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cassetteWarmGray.opacity(0.5), lineWidth: 1)
                                    )

                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.cassetteBeige.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cassetteWarmGray.opacity(0.5), lineWidth: 1)
                                    )

                                if let error = error {
                                    Text(error)
                                        .foregroundColor(.cassetteRed)
                                        .font(.footnote)
                                        .padding(.horizontal, 4)
                                }

                                Button(action: signIn) {
                                    HStack(spacing: 8) {
                                        if isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        } else {
                                            Text("Sign In")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: [.cassetteOrange, .cassetteRed],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .cassetteBrown.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .disabled(email.isEmpty || password.isEmpty || isLoading)
                                .opacity((email.isEmpty || password.isEmpty || isLoading) ? 0.6 : 1.0)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
                    .frame(minHeight: geometry.size.height * 0.5)
                    .background(Color.cassetteWarmGray.opacity(0.1))
                }
            }
        }
        .ignoresSafeArea()
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(_):
            // Handle successful Apple Sign In
            UserDefaults.standard.set(true, forKey: "is_authenticated")
            onSuccess()
        case .failure(let error):
            self.error = "Apple Sign In failed: \(error.localizedDescription)"
        }
    }

    private func handleGoogleSignIn() {
        // Mock Google Sign In for now
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            UserDefaults.standard.set(true, forKey: "is_authenticated")
            onSuccess()
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
                error = "Invalid credentials. Try any email and 4+ character password."
            }
        }
    }
}

