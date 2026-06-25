import SwiftUI

struct ContractArticleManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contracts: [Contract] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showAddContract = false
    @State private var showCopyContract = false
    @State private var showAddMenu = false
    @State private var contractToDelete: Contract? = nil
    @State private var deleteErrorMessage: String? = nil
    @State private var isSaving = false
    @State private var isCopying = false
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()

    private var filteredContracts: [Contract] {
        guard !searchText.isEmpty else { return contracts }
        return contracts.filter {
            ($0.clientname ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.contractname ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedContracts: [(letter: String, contracts: [Contract])] {
        let dict = Dictionary(grouping: filteredContracts) { c -> String in
            let first = String((c.clientname ?? "#").prefix(1)).uppercased()
            return first.first?.isLetter == true ? first : "#"
        }
        return dict.keys.sorted().map { key in
            (letter: key, contracts: dict[key]!.sorted { ($0.clientname ?? "") < ($1.clientname ?? "") })
        }
    }

    private var indexLetters: [String] { groupedContracts.map { $0.letter } }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isLoading {
                    ProgressView("Lade Verträge...")
                        .font(Equans.Fonts.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 12) {
                        Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                        Button("Erneut laden") { loadContracts() }
                            .foregroundColor(Equans.Colors.darkBlue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contracts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Equans.Colors.darkGreen)
                        Text("Keine Verträge vorhanden.")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        List {
                            if filteredContracts.isEmpty {
                                Section {
                                    Text("Keine Treffer für \"\(searchText)\".")
                                        .foregroundColor(Equans.Colors.textSecondary)
                                        .font(Equans.Fonts.callout)
                                }
                            } else {
                                ForEach(groupedContracts, id: \.letter) { section in
                                    Section(header: Text(section.letter)
                                        .font(Equans.Fonts.roboto(13, weight: .bold))
                                        .foregroundColor(Equans.Colors.darkBlue)
                                        .id(section.letter)
                                    ) {
                                        ForEach(section.contracts) { contract in
                                            NavigationLink(value: contract) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(contract.clientname ?? "(kein Kunde)")
                                                        .font(Equans.Fonts.headline)
                                                        .foregroundColor(Equans.Colors.textPrimary)
                                                    Text(contract.contractname ?? "(kein Vertrag)")
                                                        .font(Equans.Fonts.callout)
                                                        .foregroundColor(Equans.Colors.textSecondary)
                                                }
                                            }
                                            .listRowBackground(Equans.Colors.surface)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    contractToDelete = contract
                                                } label: {
                                                    Label("Löschen", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .searchable(text: $searchText, prompt: "Kunde oder Vertrag suchen…")
                        .overlay(alignment: .trailing) {
                            if searchText.isEmpty && !indexLetters.isEmpty {
                                ContractAlphabetIndex(letters: indexLetters) { letter in
                                    withAnimation { proxy.scrollTo(letter, anchor: .top) }
                                }
                                .padding(.trailing, 4)
                            }
                        }
                    }
                }
            }
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Verträge & Artikel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMenu = true }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(Equans.Colors.darkBlue)
                    .disabled(isCopying)
                    .overlay {
                        if isCopying { ProgressView().scaleEffect(0.7) }
                    }
                }
            }
            .onAppear(perform: loadContracts)
            .navigationDestination(for: Contract.self) { contract in
                ContractDetailEditView(contract: contract, onChange: loadContracts)
            }
            .confirmationDialog("Vertrag hinzufügen", isPresented: $showAddMenu, titleVisibility: .visible) {
                Button("Neuer Vertrag") { showAddContract = true }
                Button("Vertrag kopieren") { showCopyContract = true }
                Button("Abbrechen", role: .cancel) {}
            }
            .sheet(isPresented: $showCopyContract, onDismiss: loadContracts) {
                CopyContractSheet(contracts: contracts, isCopying: $isCopying) { source in
                    isCopying = true
                    SupabaseManager.shared.copyContract(source: source) { result in
                        DispatchQueue.main.async {
                            isCopying = false
                            if case .failure(let err) = result { error = err.localizedDescription }
                            else { loadContracts() }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddContract) {
                AddContractSheet(isSaving: $isSaving) { clientName, contractName in
                    isSaving = true
                    SupabaseManager.shared.insertContract(
                        clientname: clientName.isEmpty ? nil : clientName,
                        contractname: contractName.isEmpty ? nil : contractName
                    ) { result in
                        DispatchQueue.main.async {
                            isSaving = false
                            if case .failure(let err) = result { error = err.localizedDescription }
                            else { loadContracts() }
                        }
                    }
                }
            }
            .alert("Vertrag löschen?", isPresented: Binding(
                get: { contractToDelete != nil },
                set: { if !$0 { contractToDelete = nil } }
            )) {
                Button("Abbrechen", role: .cancel) { contractToDelete = nil }
                Button("Löschen", role: .destructive) {
                    if let contract = contractToDelete {
                        deleteContract(contract)
                    }
                    contractToDelete = nil
                }
            } message: {
                Text("Möchten Sie diesen Vertrag wirklich löschen? Zugehörige Artikelgruppen und Artikel werden ebenfalls entfernt. Verträge mit bestehenden Buchungen können nicht gelöscht werden.")
            }
            .alert("Löschen nicht möglich", isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { deleteErrorMessage = nil }
            } message: {
                Text(deleteErrorMessage ?? "")
            }
        }
    }
    
    private func loadContracts() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchContracts { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let contracts):
                    self.contracts = contracts.sorted { ($0.clientname ?? "") < ($1.clientname ?? "") }
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }
    
    private func deleteContract(_ contract: Contract) {
        SupabaseManager.shared.deleteContractCascade(id: contract.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadContracts()
                case .failure(let err):
                    // Fehler als Hinweis anzeigen, Liste bleibt erhalten.
                    self.deleteErrorMessage = err.localizedDescription
                }
            }
        }
    }
}

private struct ContractAlphabetIndex: View {
    let letters: [String]
    let onSelect: (String) -> Void
    @GestureState private var dragLetter: String? = nil

    var body: some View {
        VStack(spacing: 2) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(dragLetter == letter ? .white : Equans.Colors.darkBlue)
                    .frame(width: 20, height: 20)
                    .background(dragLetter == letter ? Equans.Colors.darkBlue : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(Equans.Colors.surface.opacity(0.85))
        .cornerRadius(10)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($dragLetter) { value, state, _ in
                    let index = Int(value.location.y / 22)
                    if index >= 0 && index < letters.count {
                        let letter = letters[index]
                        if state != letter { state = letter; onSelect(letter) }
                    }
                }
        )
        .onTapGesture {}
    }
}

private struct CopyContractSheet: View {
    let contracts: [Contract]
    @Binding var isCopying: Bool
    var onCopy: (Contract) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [Contract] {
        guard !searchText.isEmpty else { return contracts }
        return contracts.filter {
            ($0.contractname ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.clientname ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filtered) { contract in
                    Button(action: {
                        onCopy(contract)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contract.clientname ?? "(kein Kunde)")
                                .font(Equans.Fonts.headline)
                                .foregroundColor(Equans.Colors.textPrimary)
                            Text(contract.contractname ?? "(kein Vertrag)")
                                .font(Equans.Fonts.callout)
                                .foregroundColor(Equans.Colors.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(Equans.Colors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Vertrag suchen…")
            .navigationTitle("Vertrag kopieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Equans.Colors.textSecondary)
                }
            }
        }
    }
}

private struct AddContractSheet: View {
    @Binding var isSaving: Bool
    var onSave: (_ clientName: String, _ contractName: String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var clientName = ""
    @State private var contractName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kunde")) {
                    TextField("Kundenname", text: $clientName)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
                Section(header: Text("Vertrag")) {
                    TextField("Vertragsname", text: $contractName)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Neuer Vertrag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Equans.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        onSave(clientName.trimmingCharacters(in: .whitespaces),
                               contractName.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Equans.Colors.darkBlue)
                    .disabled(isSaving || (clientName.trimmingCharacters(in: .whitespaces).isEmpty && contractName.trimmingCharacters(in: .whitespaces).isEmpty))
                }
            }
        }
    }
}
