//
//  LoginView.swift
//  FMKasse
//
//  Erstellt von Cascade AI am 09.07.2025.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @Binding var isLoggedIn: Bool
    @State private var offsetY: CGFloat = -300
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var isSSOLoading = false
    
    private let emailKey = "savedEmail"
    private let passwordKey = "savedPassword"
    
    private func loadCredentials() {
        if let savedEmail = UserDefaults.standard.string(forKey: emailKey) {
            email = savedEmail
        }
        if let savedPassword = UserDefaults.standard.string(forKey: passwordKey) {
            password = savedPassword
        }
    }
    
    private func saveCredentials() {
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
    }

    var body: some View {
        ZStack {
            Equans.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    Image("Equans_White")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220)
                        .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
                        .offset(y: offsetY)
                        .padding(.top, 60)
                        .padding(.bottom, 8)
                    
                    Text("Willkommen")
                        .font(Equans.Fonts.roboto(26, weight: .black))
                        .foregroundColor(Equans.Colors.textPrimary)
                    Text("Bitte melden Sie sich an")
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textSecondary)
                    
                    VStack(spacing: 14) {
                        TextField("E-Mail", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                            .tint(Equans.Colors.darkBlue)
                            .padding(14)
                            .background(Equans.Colors.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Equans.Colors.border, lineWidth: 1))
                        SecureField("Passwort", text: $password)
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                            .tint(Equans.Colors.darkBlue)
                            .padding(14)
                            .background(Equans.Colors.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Equans.Colors.border, lineWidth: 1))
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(Equans.Fonts.caption)
                            .foregroundColor(Equans.Colors.danger)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("Anmelden") {
                        saveCredentials()
                        login()
                    }
                    .buttonStyle(EquansPrimaryButtonStyle())
                    
                    if AuthConfig.azureSSOEnabled {
                        HStack {
                            VStack { Divider() }
                            Text("oder")
                                .font(Equans.Fonts.caption)
                                .foregroundColor(Equans.Colors.textSecondary)
                            VStack { Divider() }
                        }
                        .padding(.vertical, 2)
                        
                        Button(action: { loginWithAzure() }) {
                            HStack {
                                if isSSOLoading {
                                    ProgressView().tint(Equans.Colors.darkBlue)
                                } else {
                                    Image(systemName: "person.badge.key.fill")
                                }
                                Text("Mit EQUANS-Konto anmelden")
                            }
                        }
                        .buttonStyle(EquansSecondaryButtonStyle())
                        .disabled(isSSOLoading)
                    }
                    
                    Text("FM Kasse \(AppInfo.versionString)")
                        .font(Equans.Fonts.roboto(11, weight: .light))
                        .foregroundColor(Equans.Colors.textSecondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadCredentials()
            offsetY = -320
            scaleX = 1.0
            scaleY = 1.0

            // Erster Aufprall: von oben fallen
            withAnimation(.easeIn(duration: 0.45)) {
                offsetY = 0
            }
            // Aufprall 1: Squash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.1)) {
                    scaleX = 1.3; scaleY = 0.7
                }
            }
            // Bounce 1: hoch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.28)) {
                    scaleX = 1.0; scaleY = 1.0; offsetY = -90
                }
            }
            // Aufprall 2: Squash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.83) {
                withAnimation(.easeIn(duration: 0.18)) {
                    offsetY = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.01) {
                withAnimation(.easeOut(duration: 0.08)) {
                    scaleX = 1.15; scaleY = 0.82
                }
            }
            // Bounce 2: kleiner
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.09) {
                withAnimation(.easeOut(duration: 0.18)) {
                    scaleX = 1.0; scaleY = 1.0; offsetY = -30
                }
            }
            // Aufprall 3: zur Ruhe kommen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.27) {
                withAnimation(.easeIn(duration: 0.12)) {
                    offsetY = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.39) {
                withAnimation(.easeOut(duration: 0.12)) {
                    scaleX = 1.0; scaleY = 1.0
                }
            }
        }
    }
    
    func login() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
                await AppSession.shared.handleLoginSuccess(
                    userId: session.user.id.uuidString,
                    email: session.user.email
                )
                isLoggedIn = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loginWithAzure() {
        errorMessage = nil
        isSSOLoading = true
        Task {
            do {
                try await SupabaseManager.shared.signInWithAzure()
                if let session = try? await SupabaseManager.shared.client.auth.session {
                    await AppSession.shared.handleLoginSuccess(
                        userId: session.user.id.uuidString,
                        email: session.user.email
                    )
                }
                isSSOLoading = false
                isLoggedIn = true
            } catch {
                isSSOLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
