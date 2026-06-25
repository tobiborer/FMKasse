import SwiftUI

struct NewBookingContractSelectionView: View {
    @ObservedObject private var deviceRepo = DeviceRepository.shared
    @State private var contracts: [Contract] = []
    @State private var isLoading = true
    @State private var error: String?
    @StateObject private var journalDraft = BookJournalDraft(
        fk_contract: 0, // Platzhalter, wird beim Öffnen gesetzt
        contract: Contract(
            id: 0, created_at: "", clientname: nil, contractname: nil, contractdate: nil, contractvalid: nil, contractlogo: nil,
            contractreference_1: nil, contractreference_2: nil, contractreference_3: nil, contractreference_4: nil, contractclientno: nil, contractshortname: nil,
            contractclientdep: nil, contractclientadress_1: nil, contractclientadress_2: nil, contractclientadress_zip: nil, contractclientadress_city: nil, contractclienttaxid: nil,
            contractstandardcostcenter: nil, needobjectdefinition: nil, needplanonrderdefinition: nil, contractplanonref: nil, contractplanonreference_syscode: nil, contractsapobjectlink: nil, contractowner: nil
        )
    )
    @State private var showDraftDetail = false
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredContracts: [Contract] {
        guard !searchText.isEmpty else { return contracts }
        return contracts.filter {
            ($0.clientname ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.contractname ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Notification-Listener für Transaktionsabschluss
    @State private var transactionListener: NSObjectProtocol? = nil
    
    var body: some View {
        return NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Lade Verträge...")
                        .font(Equans.Fonts.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contracts.isEmpty {
                    Text("Keine Verträge gefunden.")
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Equans.Colors.textSecondary)
                            TextField("Kunde oder Vertrag suchen…", text: $searchText)
                                .font(Equans.Fonts.body)
                                .foregroundColor(Equans.Colors.textPrimary)
                                .autocorrectionDisabled()
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Equans.Colors.textSecondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Equans.Colors.surface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Equans.Colors.border, lineWidth: 1))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    ScrollView {
                        if filteredContracts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundColor(Equans.Colors.border)
                                Text("Keine Treffer für \"\(searchText)\".")
                                    .font(Equans.Fonts.callout)
                                    .foregroundColor(Equans.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                            ForEach(filteredContracts, id: \.id) { contract in
                                ContractCard(contract: contract) {
                                    // Draft-Objekt zentral als StateObject befüllen
                                    self.journalDraft.fk_contract = contract.id
                                    self.journalDraft.fk_machine = deviceRepo.selectedMachineId
                                    self.journalDraft.bookreference1 = contract.contractreference_1
                                    self.journalDraft.bookreference2 = contract.contractreference_2
                                    self.journalDraft.fk_objectorigin = nil
                                    self.journalDraft.fk_objectdestination = nil
                                    self.journalDraft.fk_order = nil
                                    self.journalDraft.contract = contract
                                    self.journalDraft.machine = nil
                                    self.showDraftDetail = true
                                }
                            }
                        }
                        .padding(24)
                        } // end if filteredContracts.isEmpty
                    } // end ScrollView
                    } // end VStack
                }
                HStack(spacing: 24) {
                    ActionTile(title: "Schließen", systemImage: "xmark", color: Equans.Colors.textSecondary) {
                        dismiss()
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
            }
            .background(Equans.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Vertrag wählen")
                    .font(Equans.Fonts.roboto(13, weight: .medium))
                    .foregroundColor(Equans.Colors.darkBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Equans.Colors.turquoise.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .onAppear {
            loadContracts()
            // Notification-Listener setzen
            transactionListener = NotificationCenter.default.addObserver(forName: .didCompleteTransaction, object: nil, queue: .main) { _ in
                dismiss()
            }
        }
        .onDisappear {
            if let listener = transactionListener {
                NotificationCenter.default.removeObserver(listener)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .fullScreenCover(isPresented: $showDraftDetail) {
            NewBookingJournalDraftDetail(
                draft: journalDraft,
                onSave: { _ in self.showDraftDetail = false },
                onCancel: { self.showDraftDetail = false }
            )
        }
    
    
    func loadContracts() {
        guard let machineId = deviceRepo.selectedMachineId else {
            self.contracts = []
            self.isLoading = false
            return
        }
        isLoading = true
        error = nil
        // Lade alle MachineConfigs für das Gerät
        SupabaseManager.shared.fetchMachineConfigs { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let configs):
                    let relevantArticlegroupIds = configs.filter { $0.fk_machine == machineId }.compactMap { $0.fk_articlegroup }
                    if relevantArticlegroupIds.isEmpty {
                        self.contracts = []
                        self.isLoading = false
                        return
                    }
                    // Lade alle ArticleGroups
                    SupabaseManager.shared.fetchArticleGroups { agResult in
                        DispatchQueue.main.async {
                            switch agResult {
                            case .success(let groups):
                                let relevantContractIds = groups.filter { relevantArticlegroupIds.contains($0.id) }.compactMap { $0.fk_contract }
                                if relevantContractIds.isEmpty {
                                    self.contracts = []
                                    self.isLoading = false
                                    return
                                }
                                // Lade alle Contracts
                                SupabaseManager.shared.fetchContracts { cResult in
                                    DispatchQueue.main.async {
                                        switch cResult {
                                        case .success(let contracts):
                                            let filtered = contracts.filter { relevantContractIds.contains($0.id) }
                                                .sorted { ($0.clientname ?? "") < ($1.clientname ?? "") }
                                            self.contracts = filtered
                                            self.isLoading = false
                                        case .failure(let err):
                                            self.error = err.localizedDescription
                                            self.isLoading = false
                                        }
                                    }
                                }
                            case .failure(let err):
                                self.error = err.localizedDescription
                                self.isLoading = false
                            }
                        }
                    }
                case .failure(let err):
                    self.error = err.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

}
struct ContractCard: View {
    let contract: Contract
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .center, spacing: 8) {
                Text(contract.clientname ?? "(kein Kunde)")
                    .font(Equans.Fonts.headline)
                    .foregroundColor(Equans.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(contract.contractname ?? "(kein Vertrag)")
                    .font(Equans.Fonts.callout)
                    .foregroundColor(Equans.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Equans.Colors.surface)
            .cornerRadius(Equans.Layout.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                    .stroke(Equans.Colors.border, lineWidth: 1)
            )
            .shadow(color: Equans.Layout.cardShadow, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
