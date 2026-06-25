//
//  MainMenuView.swift
//  FMKasse
//
//  Erstellt von Cascade AI am 09.07.2025.
//

import SwiftUI

struct MainMenuView: View {
    @StateObject private var session = AppSession.shared
    @State private var showSettings = false
    @State private var showKassenterminal = false
    @State private var showContractManagement = false
    @State private var showReporting = false
    @State private var showUserManagement = false

    private var appVersionString: String { AppInfo.versionString }
    private var role: UserRole { session.role }

    var body: some View {
        NavigationStack {
            ZStack {
                Equans.Colors.background.ignoresSafeArea()

                if session.isLoadingProfile {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Profil wird geladen…")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                } else {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 8)
                        Image("Equans_White")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 88)
                            .padding(.top, 16)

                        // Rolle-Badge
                        HStack(spacing: 6) {
                            Image(systemName: role.icon)
                            Text(role.label)
                                .font(Equans.Fonts.roboto(12, weight: .semibold))
                        }
                        .foregroundColor(role.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(role.color.opacity(0.1))
                        .cornerRadius(20)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)],
                            spacing: 18
                        ) {
                            // USER+
                            Button(action: { showKassenterminal = true }) {
                                MenuTile(title: "Kassenterminal", systemImage: "creditcard.fill", accent: Equans.Colors.darkBlue)
                            }
                            Button(action: { showReporting = true }) {
                                MenuTile(title: "Reporting", systemImage: "chart.xyaxis.line", accent: Equans.Colors.darkGreen)
                            }
                            // SUPERUSER+
                            if role >= .superuser {
                                Button(action: { showContractManagement = true }) {
                                    MenuTile(title: "Verträge & Artikel", systemImage: "doc.append", accent: Equans.Colors.darkGreen)
                                }
                            }
                            // ADMIN only
                            if role == .admin {
                                Button(action: { showSettings = true }) {
                                    MenuTile(title: "Einstellungen", systemImage: "slider.horizontal.3", accent: Equans.Colors.darkBlue)
                                }
                                Button(action: { showUserManagement = true }) {
                                    MenuTile(title: "Benutzer", systemImage: "person.2.fill", accent: Equans.Colors.darkBlue)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        Spacer()
                        MachineInfoBox()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Text(appVersionString)
                        .font(Equans.Fonts.roboto(11, weight: .light))
                        .foregroundColor(Equans.Colors.textSecondary)
                    Spacer()
                    Button(action: { session.logout() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Abmelden")
                        }
                        .font(Equans.Fonts.roboto(11, weight: .light))
                        .foregroundColor(Equans.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(Equans.Colors.background)
            }
            .sheet(isPresented: $showSettings) { SettingsMenuView() }
            .sheet(isPresented: $showUserManagement) { UserManagementView() }
            .fullScreenCover(isPresented: $showKassenterminal) { KassenterminalListView() }
            .fullScreenCover(isPresented: $showContractManagement) { ContractArticleManagementView() }
            .fullScreenCover(isPresented: $showReporting) { ReportingMenuView() }
        }
    }
}

struct MenuTile: View {
    let title: String
    let systemImage: String
    var accent: Color = Equans.Colors.darkBlue
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accent)
            }
            Text(title)
                .font(Equans.Fonts.tileTitle)
                .foregroundColor(Equans.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .padding(.horizontal, 8)
        .background(Equans.Colors.surface)
        .cornerRadius(Equans.Layout.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                .stroke(Equans.Colors.border, lineWidth: 1)
        )
        .shadow(color: Equans.Layout.cardShadow, radius: 8, x: 0, y: 3)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
