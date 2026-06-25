import Foundation
import SwiftUI

// MARK: - Role

enum UserRole: String, Codable, CaseIterable, Comparable {
    case user      = "USER"
    case superuser = "SUPERUSER"
    case admin     = "ADMIN"

    private var level: Int {
        switch self { case .user: return 0; case .superuser: return 1; case .admin: return 2 }
    }
    static func < (lhs: UserRole, rhs: UserRole) -> Bool { lhs.level < rhs.level }

    var label: String {
        switch self {
        case .user:      return "User"
        case .superuser: return "Superuser"
        case .admin:     return "Admin"
        }
    }

    var icon: String {
        switch self {
        case .user:      return "person.fill"
        case .superuser: return "person.badge.plus"
        case .admin:     return "shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .user:      return Equans.Colors.textSecondary
        case .superuser: return Equans.Colors.darkBlue
        case .admin:     return Equans.Colors.darkGreen
        }
    }
}

// MARK: - AppUser

struct AppUser: Codable, Identifiable {
    let id: String
    let email: String?
    let displayname: String?
    let role: UserRole
    let created_at: String?
    /// Optional einer Kasse zugeordnet – wird beim Login automatisch als Gerät übernommen.
    let fk_machine: Int64?
}

struct AppUserInsert: Encodable {
    let id: String
    let email: String?
    let displayname: String?
    let role: String
}

struct AppUserRoleUpdate: Encodable {
    let role: String
    let displayname: String?
    let fk_machine: Int64?

    enum CodingKeys: String, CodingKey { case role, displayname, fk_machine }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(displayname, forKey: .displayname)
        // fk_machine bewusst auch als null kodieren, damit "Keine Kasse" die Zuordnung löscht.
        try container.encode(fk_machine, forKey: .fk_machine)
    }
}

// MARK: - AppSession

@MainActor
class AppSession: ObservableObject {
    static let shared = AppSession()

    @Published var isLoggedIn = false
    @Published var currentUser: AppUser? = nil
    @Published var isLoadingProfile = false
    @Published var profileError: String? = nil

    var role: UserRole { currentUser?.role ?? .user }

    func handleLoginSuccess(userId: String, email: String?) async {
        isLoggedIn = true
        isLoadingProfile = true
        profileError = nil

        await loadOrCreateProfile(userId: userId, email: email)
        isLoadingProfile = false
    }

    func logout() {
        isLoggedIn = false
        currentUser = nil
        Task {
            try? await SupabaseManager.shared.client.auth.signOut()
        }
    }

    /// Setzt die dem Benutzer zugeordnete Kasse als aktives Gerät.
    /// Nur User mit Admin-Rechten können das Gerät in den Einstellungen selbst wählen;
    /// für alle anderen wird die zugeordnete Kasse beim Login automatisch übernommen.
    /// Hat der Benutzer keine Zuordnung, bleibt die bisherige Geräteauswahl unverändert.
    private func applyAssignedMachine(_ user: AppUser) {
        if let machineId = user.fk_machine {
            DeviceRepository.shared.selectedMachineId = machineId
        }
    }

    private func loadOrCreateProfile(userId: String, email: String?) async {
        await withCheckedContinuation { continuation in
            SupabaseManager.shared.fetchUserProfile(userId: userId) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let user):
                        if let user = user {
                            self.currentUser = user
                            self.applyAssignedMachine(user)
                            continuation.resume()
                        } else {
                            // Erstes Login → Profil anlegen (USER-Rolle)
                            SupabaseManager.shared.insertUserProfile(
                                userId: userId, email: email, displayname: nil, role: .user
                            ) { insertResult in
                                Task { @MainActor in
                                    if case .success = insertResult {
                                        self.currentUser = AppUser(
                                            id: userId, email: email,
                                            displayname: nil, role: .user, created_at: nil,
                                            fk_machine: nil
                                        )
                                    } else if case .failure(let err) = insertResult {
                                        self.profileError = err.localizedDescription
                                    }
                                    continuation.resume()
                                }
                            }
                        }
                    case .failure(let err):
                        self.profileError = err.localizedDescription
                        continuation.resume()
                    }
                }
            }
        }
    }
}
