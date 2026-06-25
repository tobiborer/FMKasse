//
//  FMKasseApp.swift
//  FMKasse
//
//  Created by Tobias Borer on 09.07.2025.
//

import SwiftUI

@main
struct FMKasseApp: App {
    @StateObject private var session = AppSession.shared
    @State private var showSetPassword = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !session.isLoggedIn {
                    LoginView(isLoggedIn: $session.isLoggedIn)
                } else {
                    MainMenuView()
                }
            }
            .sheet(isPresented: $showSetPassword) {
                SetPasswordView {
                    showSetPassword = false
                }
            }
            .onOpenURL { url in
                guard url.scheme == AuthConfig.redirectScheme else { return }

                // Fragment (#) parsen um den Link-Typ zu bestimmen
                let fragment = url.fragment ?? ""
                let params   = fragmentParams(fragment)
                let linkType = params["type"] ?? ""

                Task {
                    do {
                        try await SupabaseManager.shared.handleOAuthCallback(url: url)

                        if linkType == "invite" || linkType == "recovery" {
                            // Passwort-setzen-Screen anzeigen
                            await MainActor.run { showSetPassword = true }
                        } else {
                            // Normaler OAuth-Login (Azure AD)
                            await AppSession.shared.handleLoginSuccess(
                                userId: SupabaseManager.shared.client.auth.currentUser?.id.uuidString ?? "",
                                email: SupabaseManager.shared.client.auth.currentUser?.email
                            )
                        }
                    } catch {
                        print("[Auth] Deep-Link-Fehler: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func fragmentParams(_ fragment: String) -> [String: String] {
        var result: [String: String] = [:]
        for part in fragment.split(separator: "&") {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                result[String(kv[0])] = String(kv[1])
            }
        }
        return result
    }
}
