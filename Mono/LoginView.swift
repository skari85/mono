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
                    // Top section with minimal branding
                    VStack(spacing: 40) {
                        Spacer(minLength: 80)

                        // Monotrans Logo with minimal design
                        VStack(spacing: 24) {
                            // Monotrans logo image
                            Image("Monotrans")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                            // Clean typography
                            VStack(spacing: 8) {
                                Text("Mono")
                                    .font(.system(size: 42, weight: .light, design: .default))
                                    .foregroundColor(.cassetteTextDark)
                                    .tracking(2)

                                Text("Minimalist AI Chat")
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundColor(.cassetteTextMedium)
                                    .tracking(1)
                            }
                        }

                        Spacer(minLength: 60)
                    }
                    .frame(minHeight: geometry.size.height * 0.5)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.cassetteBeige.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Bottom section with login options
                    VStack(spacing: 32) {
                        VStack(spacing: 24) {
                            Text("Welcome back")
                                .font(.system(size: 24, weight: .light, design: .default))
                                .foregroundColor(.cassetteTextDark)
                                .tracking(0.5)

                            // Apple Sign In
                            SignInWithAppleButton(.signIn) { request in
                                // Configure Apple Sign In request
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 52)
                            .cornerRadius(16)

                            // Google Sign In Button
                            Button(action: handleGoogleSignIn) {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .foregroundColor(.cassetteTextDark)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cassetteWarmGray.opacity(0.4), lineWidth: 1)
                                )
                            }


                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.cassetteTextMedium.opacity(0.2))
                                    .frame(height: 0.5)
                                Text("or")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.cassetteTextMedium)
                                    .padding(.horizontal, 20)
                                Rectangle()
                                    .fill(Color.cassetteTextMedium.opacity(0.2))
                                    .frame(height: 0.5)
                            }

                            // Email/Password Form
                            VStack(spacing: 20) {
                                TextField("Email", text: $email)
                                    .textContentType(.username)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 16, weight: .regular))
                                    .padding(18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.cassetteWarmGray.opacity(0.3), lineWidth: 1)
                                    )

                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                                    .font(.system(size: 16, weight: .regular))
                                    .padding(18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.cassetteWarmGray.opacity(0.3), lineWidth: 1)
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
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        LinearGradient(
                                            colors: [.cassetteTextDark, .cassetteTextDark.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                                .disabled(email.isEmpty || password.isEmpty || isLoading)
                                .opacity((email.isEmpty || password.isEmpty || isLoading) ? 0.6 : 1.0)
                            }
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 40)
                    .frame(minHeight: geometry.size.height * 0.5)
                    .background(Color.white)
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

