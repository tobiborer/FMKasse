import SwiftUI


// Hilfs-Binding für optionale Strings als echte Binding-Property
extension Binding where Value == String? {
    var orEmpty: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}


struct NewBookingJournalDraftDetail: View {
    @ObservedObject var draft: BookJournalDraft
    @State private var machine: Machine? = nil
    @State private var isLoadingMachine = false
    @State private var showAddPositionSheet = false
    @Environment(\.dismiss) private var dismiss
    @State private var transactionListener: NSObjectProtocol? = nil
    @State private var draftDetails: [BookDetailDraft] = []
    var onSave: (BookJournalDraft) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Neue Buchung")
                    .font(Equans.Fonts.title)
                    .foregroundColor(Equans.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .padding(.horizontal)
                Spacer().frame(height: 8)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Kunde:")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .frame(width: 110, alignment: .leading)
                        Text(draft.contract.clientname ?? "-")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                    }
                    HStack {
                        Text("Vertrag:")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .frame(width: 110, alignment: .leading)
                        Text(draft.contract.contractname ?? "-")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                    }
                    HStack {
                        Text("Kasse:")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .frame(width: 110, alignment: .leading)
                        Text(machine?.machinename ?? (draft.fk_machine != nil ? "#\(draft.fk_machine!)" : "-"))
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                    }
                    HStack {
                        Text("Referenz 1:")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .frame(width: 110, alignment: .leading)
                        TextField("Referenz 1", text: $draft.bookreference1.orEmpty)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Referenz 2:")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .frame(width: 110, alignment: .leading)
                        TextField("Referenz 2", text: $draft.bookreference2.orEmpty)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .background(Equans.Colors.surface)
                .cornerRadius(Equans.Layout.cardRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                        .stroke(Equans.Colors.border, lineWidth: 1)
                )
                .padding([.top, .horizontal])

                if draftDetails.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "cart")
                            .font(.system(size: 36))
                            .foregroundColor(Equans.Colors.border)
                        Text("Noch keine Positionen")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Positionen (\(draftDetails.count))")
                                .font(Equans.Fonts.callout)
                                .foregroundColor(Equans.Colors.textSecondary)
                            Spacer()
                            let total = draftDetails.compactMap { d -> Double? in
                                guard let qty = d.booknbrsarticle, let price = d.bookdetailprice else { return nil }
                                return qty * price
                            }.reduce(0, +)
                            Text(String(format: "Total: %.2f CHF", total))
                                .font(Equans.Fonts.roboto(13, weight: .bold))
                                .foregroundColor(Equans.Colors.darkGreen)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                        List {
                            ForEach(draftDetails) { detail in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(detail.articletitle ?? "Artikel")
                                            .font(Equans.Fonts.body)
                                            .foregroundColor(Equans.Colors.textPrimary)
                                        if let descr = detail.bookdetaildescr {
                                            Text(descr)
                                                .font(Equans.Fonts.caption)
                                                .foregroundColor(Equans.Colors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if let qty = detail.booknbrsarticle, let price = detail.bookdetailprice {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(String(format: "%.2f CHF", qty * price))
                                                .font(Equans.Fonts.roboto(13, weight: .bold))
                                                .foregroundColor(Equans.Colors.textPrimary)
                                            Text(String(format: "%.0f × %.2f", qty, price))
                                                .font(Equans.Fonts.caption)
                                                .foregroundColor(Equans.Colors.textSecondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete { draftDetails.remove(atOffsets: $0) }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
                HStack(spacing: 0) {
                    Spacer()
                    BookingActionButton(
                        icon: "xmark.circle.fill",
                        label: "Abbrechen",
                        color: Equans.Colors.textSecondary,
                        action: { onCancel() }
                    )
                    Spacer()
                    BookingActionButton(
                        icon: "plus.circle.fill",
                        label: "Position",
                        color: Equans.Colors.darkBlue,
                        action: { showAddPositionSheet = true }
                    )
                    Spacer()
                    BookingActionButton(
                        icon: "checkmark.circle.fill",
                        label: "Buchen",
                        color: Equans.Colors.darkGreen,
                        action: { onSave(draft) }
                    )
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Equans.Colors.surface)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Equans.Colors.border), alignment: .top)
                .padding(.bottom, 0)
            }
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear(perform: loadMachineIfNeeded)
        .fullScreenCover(isPresented: $showAddPositionSheet) {
            AddBookDetailDraftView(
                contract: draft.contract,
                machineId: draft.fk_machine ?? 0,
                draftDetails: $draftDetails,
                onCancel: { self.showAddPositionSheet = false },
                onTransactionComplete: {
                    self.showAddPositionSheet = false
                    self.reloadAfterTransaction()
                }
            )
        }
        .onAppear {
            transactionListener = NotificationCenter.default.addObserver(forName: .didCompleteTransaction, object: nil, queue: .main) { _ in
                dismiss()
            }
        }
        .onDisappear {
            if let listener = transactionListener {
                NotificationCenter.default.removeObserver(listener)
            }
        }
    }
    
    private func loadMachineIfNeeded() {
        guard machine == nil, let machineId = draft.fk_machine else { return }
        isLoadingMachine = true
        SupabaseManager.shared.fetchMachines { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let machines):
                    self.machine = machines.first(where: { $0.id == machineId })
                case .failure:
                    break
                }
                isLoadingMachine = false
            }
        }
    }
    
    private func reloadAfterTransaction() {
        // Hier Übersicht/Buchungsdetails neu laden (z.B. fetchBookJournals() oder Notification)
        // Beispiel: print("Transaktion abgeschlossen – Übersicht könnte neu geladen werden.")
    }
}

private struct BookingActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .regular))
                Text(label)
                    .font(Equans.Fonts.caption)
            }
            .foregroundColor(color)
            .frame(minWidth: 72)
        }
    }
}
