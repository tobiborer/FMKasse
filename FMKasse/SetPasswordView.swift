import SwiftUI

struct SetPasswordView: View {
    var onDone: () -> Void

    @State private var password        = ""
    @State private var passwordConfirm = ""
    @State private var isSaving        = false
    @State private var errorMessage: String?
    @State private var didSucceed      = false

    private var isValid: Bool {
        password.count >= 8 && password == passwordConfirm
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Neues Passwort", text: $password)
                        .textContentType(.newPassword)
                    SecureField("Passwort bestätigen", text: $passwordConfirm)
                        .textContentType(.newPassword)
                } header: {
                    Text("Passwort festlegen")
                } footer: {
                    Text("Mindestens 8 Zeichen.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(Equans.Colors.danger)
                            .font(Equans.Fonts.caption)
                    }
                }

                if didSucceed {
                    Section {
                        Text("Passwort erfolgreich gesetzt. Sie können sich jetzt anmelden.")
                            .foregroundColor(Equans.Colors.darkGreen)
                            .font(Equans.Fonts.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Konto aktivieren")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    if didSucceed {
                        Button(action: onDone) {
                            HStack {
                                Spacer()
                                Label("Zur Anmeldung", systemImage: "arrow.right.circle.fill")
                                Spacer()
                            }
                        }
                        .buttonStyle(EquansPrimaryButtonStyle())
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Equans.Colors.background)
                    } else {
                        Button(action: save) {
                            HStack {
                                Spacer()
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Passwort speichern", systemImage: "checkmark.circle.fill")
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(EquansPrimaryButtonStyle())
                        .disabled(isSaving || !isValid)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Equans.Colors.background)
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: .init(password: password)
                )
                await MainActor.run {
                    isSaving = false
                    didSucceed = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
}
