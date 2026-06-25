import SwiftUI

struct UserManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = AppSession.shared

    @State private var users: [AppUser] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var editingUser: AppUser? = nil
    @State private var showAddUser = false
    @State private var userToDelete: AppUser? = nil

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Lade Benutzer…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 12) {
                        Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                        Button("Erneut laden") { loadUsers() }
                            .foregroundColor(Equans.Colors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if users.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Equans.Colors.border)
                        Text("Keine Benutzer gefunden.")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(users) { user in
                            Button(action: { editingUser = user }) {
                                userRow(user)
                            }
                            .listRowBackground(Equans.Colors.surface)
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first { userToDelete = users[index] }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Benutzerverwaltung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddUser = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                    .foregroundColor(Equans.Colors.darkBlue)
                }
            }
            .onAppear(perform: loadUsers)
            .sheet(isPresented: $showAddUser, onDismiss: loadUsers) {
                AddUserView()
            }
            .sheet(item: $editingUser, onDismiss: loadUsers) { user in
                EditUserView(user: user)
            }
            .alert("Benutzer entfernen?", isPresented: Binding(
                get: { userToDelete != nil },
                set: { if !$0 { userToDelete = nil } }
            )) {
                Button("Abbrechen", role: .cancel) { userToDelete = nil }
                Button("Entfernen", role: .destructive) {
                    if let user = userToDelete { deleteUser(user) }
                    userToDelete = nil
                }
            } message: {
                Text("Das Profil wird aus der Benutzerverwaltung entfernt. Der Auth-Account in Supabase bleibt bestehen.")
            }
        }
    }

    @ViewBuilder
    private func userRow(_ user: AppUser) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(user.role.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: user.role.icon)
                    .font(.system(size: 18))
                    .foregroundColor(user.role.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(user.displayname ?? user.email ?? user.id)
                    .font(Equans.Fonts.body)
                    .foregroundColor(Equans.Colors.textPrimary)
                if let email = user.email, user.displayname != nil {
                    Text(email)
                        .font(Equans.Fonts.caption)
                        .foregroundColor(Equans.Colors.textSecondary)
                }
            }
            Spacer()
            Text(user.role.label)
                .font(Equans.Fonts.roboto(12, weight: .semibold))
                .foregroundColor(user.role.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(user.role.color.opacity(0.1))
                .cornerRadius(12)
            // Eigenes Profil nicht löschen
            if user.id == session.currentUser?.id {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Equans.Colors.darkGreen)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func loadUsers() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchAllUserProfiles { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let u): users = u
                case .failure(let err): error = err.localizedDescription
                }
            }
        }
    }

    private func deleteUser(_ user: AppUser) {
        guard user.id != session.currentUser?.id else { return }
        SupabaseManager.shared.deleteUserProfile(userId: user.id) { result in
            DispatchQueue.main.async {
                if case .failure(let err) = result { error = err.localizedDescription }
                else { loadUsers() }
            }
        }
    }
}

// MARK: - Edit User

struct EditUserView: View {
    let user: AppUser
    @Environment(\.dismiss) private var dismiss
    @State private var displayname: String
    @State private var selectedRole: UserRole
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(user: AppUser) {
        self.user = user
        _displayname = State(initialValue: user.displayname ?? "")
        _selectedRole = State(initialValue: user.role)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Benutzer") {
                    HStack {
                        Text("E-Mail")
                            .foregroundColor(Equans.Colors.textSecondary)
                            .font(Equans.Fonts.callout)
                        Spacer()
                        Text(user.email ?? "-")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                    }
                    HStack {
                        Text("Name")
                            .foregroundColor(Equans.Colors.textSecondary)
                            .font(Equans.Fonts.callout)
                            .frame(width: 80, alignment: .leading)
                        TextField("Anzeigename", text: $displayname)
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                    }
                }

                Section("Berechtigung") {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Button(action: { selectedRole = role }) {
                            HStack {
                                Image(systemName: role.icon)
                                    .foregroundColor(role.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(role.label)
                                        .font(Equans.Fonts.body)
                                        .foregroundColor(Equans.Colors.textPrimary)
                                    Text(roleDescription(role))
                                        .font(Equans.Fonts.caption)
                                        .foregroundColor(Equans.Colors.textSecondary)
                                }
                                Spacer()
                                if selectedRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Equans.Colors.darkGreen)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(Equans.Colors.danger).font(Equans.Fonts.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Benutzer bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Equans.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(Equans.Colors.darkBlue)
                        .disabled(isSaving)
                }
            }
        }
    }

    private func roleDescription(_ role: UserRole) -> String {
        switch role {
        case .user:      return "Kassenterminal, Reporting"
        case .superuser: return "+ Verträge & Artikel"
        case .admin:     return "+ Einstellungen, Benutzerverwaltung"
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        SupabaseManager.shared.updateUserProfile(
            userId: user.id,
            role: selectedRole,
            displayname: displayname.trimmingCharacters(in: .whitespaces).isEmpty ? nil : displayname.trimmingCharacters(in: .whitespaces)
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    // Eigenes Profil in Session aktualisieren
                    if user.id == AppSession.shared.currentUser?.id {
                        AppSession.shared.currentUser = AppUser(
                            id: user.id, email: user.email,
                            displayname: displayname.nilIfEmpty,
                            role: selectedRole, created_at: user.created_at
                        )
                    }
                    dismiss()
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}

// MARK: - Add User

struct AddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var displayname = ""
    @State private var selectedRole: UserRole = .user
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Konto") {
                    TextField("E-Mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(Equans.Fonts.body)
                    TextField("Anzeigename (optional)", text: $displayname)
                        .font(Equans.Fonts.body)
                }

                Section(header: Text("Berechtigung")) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Button(action: { selectedRole = role }) {
                            HStack {
                                Image(systemName: role.icon)
                                    .foregroundColor(role.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(role.label)
                                        .font(Equans.Fonts.body)
                                        .foregroundColor(Equans.Colors.textPrimary)
                                    Text(roleDescription(role))
                                        .font(Equans.Fonts.caption)
                                        .foregroundColor(Equans.Colors.textSecondary)
                                }
                                Spacer()
                                if selectedRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Equans.Colors.darkGreen)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section(footer: Text("Der Benutzer muss sich einmal mit dieser E-Mail über Supabase registrieren. Das Profil wird dann automatisch verknüpft.").font(Equans.Fonts.caption).foregroundColor(Equans.Colors.textSecondary)) {
                    EmptyView()
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(Equans.Colors.danger).font(Equans.Fonts.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Neuer Benutzer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Equans.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") { createUser() }
                        .fontWeight(.semibold)
                        .foregroundColor(Equans.Colors.darkBlue)
                        .disabled(isSaving || email.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func roleDescription(_ role: UserRole) -> String {
        switch role {
        case .user:      return "Kassenterminal, Reporting"
        case .superuser: return "+ Verträge & Artikel"
        case .admin:     return "+ Einstellungen, Benutzerverwaltung"
        }
    }

    private func createUser() {
        isSaving = true
        errorMessage = nil
        // Neuen Auth-User über Supabase Admin API anlegen (benötigt service_role key)
        // Alternativ: Profil vorab anlegen — wird beim ersten SSO-Login verknüpft
        // Hier speichern wir zunächst nur ein Platzhalter-Profil mit temporärer ID
        // Das Profil wird beim echten Login über handleLoginSuccess mit der echten UUID überschrieben
        SupabaseManager.shared.createAuthUser(
            email: email.trimmingCharacters(in: .whitespaces),
            displayname: displayname.trimmingCharacters(in: .whitespaces).isEmpty ? nil : displayname.trimmingCharacters(in: .whitespaces),
            role: selectedRole
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success: dismiss()
                case .failure(let err): errorMessage = err.localizedDescription
                }
            }
        }
    }
}
