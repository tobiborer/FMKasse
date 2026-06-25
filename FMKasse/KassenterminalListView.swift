import SwiftUI

import Foundation
import SwiftUI

struct KassenterminalListView: View {
    @ObservedObject private var deviceRepo = DeviceRepository.shared
    @State private var entries: [BookJournalAgg] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showNewBooking = false
    @State private var selectedEntry: BookJournalAgg? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    if isLoading {
                        ProgressView("Lade Buchungsjournale...")
                            .font(Equans.Fonts.body)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = error {
                        Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if entries.isEmpty {
                        Text("Keine Einträge gefunden.")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(entries) { entry in
                            Button(action: {
                                selectedEntry = entry
                            }) {
                                HStack(alignment: .top) {
                                    // Linke Seite: Vertragsinfos (hier nur ID, kann erweitert werden)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("#\(entry.journal_id)")
                                            .font(Equans.Fonts.roboto(15, weight: .bold))
                                            .foregroundColor(Equans.Colors.textPrimary)
                                        Text(entry.contractname ?? "-")
                                            .font(Equans.Fonts.callout)
                                            .foregroundColor(Equans.Colors.textPrimary)
                                        Text(entry.clientname ?? "-")
                                            .font(Equans.Fonts.callout)
                                            .foregroundColor(Equans.Colors.textSecondary)
                                        if let ref = entry.bookreference1, !ref.isEmpty {
                                            Text("Referenz: \(ref)")
                                                .font(Equans.Fonts.caption)
                                                .foregroundColor(Equans.Colors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    // Rechte Seite: Positionen und Wert
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Positionen: \(entry.position_count)")
                                            .font(Equans.Fonts.callout)
                                            .foregroundColor(Equans.Colors.textSecondary)
                                        Text(String(format: "Gesamt: %.2f CHF", entry.total_value))
                                            .font(Equans.Fonts.roboto(16, weight: .bold))
                                            .foregroundColor(Equans.Colors.darkGreen)
                                        Text(entry.created_atString)
                                            .font(Equans.Fonts.caption)
                                            .foregroundColor(Equans.Colors.textSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Equans.Colors.surface)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .background(Equans.Colors.background)
                // Kachel-Buttons immer unterhalb
                HStack(spacing: 24) {
                    ActionTile(title: "Schließen", systemImage: "xmark", color: Equans.Colors.textSecondary) {
                        dismiss()
                    }
                    ActionTile(title: "Neue Buchung", systemImage: "plus", color: Equans.Colors.darkGreen) {
                        showNewBooking = true
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
                .background(Equans.Colors.background)
            }
            .background(Equans.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Letzte Buchungen")
                                .font(Equans.Fonts.roboto(13, weight: .medium))
                                .foregroundColor(Equans.Colors.darkBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Equans.Colors.turquoise.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
            
        }
        .onAppear(perform: loadEntries)
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteTransaction)) { _ in
            loadEntries()
        }
        .edgesIgnoringSafeArea(.all)
        .fullScreenCover(isPresented: $showNewBooking, onDismiss: {
            loadEntries()
        }) {
            NewBookingContractSelectionView()
        }
        .fullScreenCover(item: $selectedEntry, onDismiss: {
            loadEntries()
        }) { entry in
            EditBookingView(entry: entry)
        }
    }
    
    private func loadEntries() {
        guard let machineId = deviceRepo.selectedMachineId else {
            self.entries = []
            self.isLoading = false
            return
        }
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchBookJournalAggs { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let aggs):
                    let filtered = aggs.filter { $0.fk_machine == machineId }
                        .sorted { $0.journal_id > $1.journal_id }
                        .prefix(20)
                    self.entries = Array(filtered)
                    self.isLoading = false
                case .failure(let err):
                    self.error = err.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
