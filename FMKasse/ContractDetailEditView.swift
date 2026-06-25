import SwiftUI

struct ContractDetailEditView: View {
    let contract: Contract
    var onChange: () -> Void
    
    // Editierbare Felder
    @State private var clientname: String
    @State private var contractname: String
    @State private var reference1: String
    @State private var reference2: String
    @State private var clientNo: String
    @State private var shortName: String
    @State private var clientDep: String
    @State private var address1: String
    @State private var address2: String
    @State private var addressZip: String
    @State private var addressCity: String
    @State private var costCenter: String
    
    @State private var isSaving = false
    @State private var saveMessage: String?
    
    // Artikelgruppen
    @State private var articleGroups: [ArticleGroup] = []
    @State private var isLoadingGroups = true
    @State private var groupError: String?
    @State private var showAddGroup = false
    @State private var showAddGroupMenu = false
    @State private var showCopyGroup = false
    @State private var isCopyingGroups = false
    @State private var groupToDelete: ArticleGroup? = nil
    
    init(contract: Contract, onChange: @escaping () -> Void) {
        self.contract = contract
        self.onChange = onChange
        _clientname = State(initialValue: contract.clientname ?? "")
        _contractname = State(initialValue: contract.contractname ?? "")
        _reference1 = State(initialValue: contract.contractreference_1 ?? "")
        _reference2 = State(initialValue: contract.contractreference_2 ?? "")
        _clientNo = State(initialValue: contract.contractclientno ?? "")
        _shortName = State(initialValue: contract.contractshortname ?? "")
        _clientDep = State(initialValue: contract.contractclientdep ?? "")
        _address1 = State(initialValue: contract.contractclientadress_1 ?? "")
        _address2 = State(initialValue: contract.contractclientadress_2 ?? "")
        _addressZip = State(initialValue: contract.contractclientadress_zip ?? "")
        _addressCity = State(initialValue: contract.contractclientadress_city ?? "")
        _costCenter = State(initialValue: contract.contractstandardcostcenter ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Vertrag")) {
                labeledField("Kunde", text: $clientname)
                labeledField("Vertragsname", text: $contractname)
                labeledField("Kürzel", text: $shortName)
                labeledField("Kundennr.", text: $clientNo)
                labeledField("Abteilung", text: $clientDep)
            }
            
            Section(header: Text("Referenzen")) {
                labeledField("Referenz 1", text: $reference1)
                labeledField("Referenz 2", text: $reference2)
                labeledField("Kostenstelle", text: $costCenter)
            }
            
            Section(header: Text("Adresse")) {
                labeledField("Adresse 1", text: $address1)
                labeledField("Adresse 2", text: $address2)
                labeledField("PLZ", text: $addressZip)
                labeledField("Ort", text: $addressCity)
            }
            
            Section {
                Button(action: saveContract) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Vertrag speichern")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(EquansPrimaryButtonStyle())
                .listRowInsets(EdgeInsets())
                .disabled(isSaving)
                if let saveMessage = saveMessage {
                    Text(saveMessage)
                        .font(Equans.Fonts.caption)
                        .foregroundColor(saveMessage.hasPrefix("Fehler") ? Equans.Colors.danger : Equans.Colors.darkGreen)
                }
            }
            
            Section(header: HStack {
                Text("Artikelgruppen")
                Spacer()
                if isCopyingGroups {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Button(action: { showAddGroupMenu = true }) {
                        Image(systemName: "plus.circle")
                    }
                    .foregroundColor(Equans.Colors.darkBlue)
                }
            }) {
                if isLoadingGroups {
                    ProgressView("Lade Gruppen...")
                } else if let groupError = groupError {
                    Text("Fehler: \(groupError)").foregroundColor(Equans.Colors.danger)
                } else if articleGroups.isEmpty {
                    Text("Keine Artikelgruppen.")
                        .foregroundColor(Equans.Colors.textSecondary)
                        .font(Equans.Fonts.callout)
                } else {
                    ForEach(articleGroups) { group in
                        NavigationLink(destination: ArticleGroupDetailView(group: group, onChange: { loadGroups() })) {
                            Text(group.groupname ?? "(kein Name)")
                                .font(Equans.Fonts.body)
                                .foregroundColor(Equans.Colors.textPrimary)
                        }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            groupToDelete = articleGroups[index]
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Equans.Colors.background.ignoresSafeArea())
        .navigationTitle(contract.clientname ?? "Vertrag")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadGroups)
        .confirmationDialog("Artikelgruppe hinzufügen", isPresented: $showAddGroupMenu, titleVisibility: .visible) {
            Button("Neue Artikelgruppe") { showAddGroup = true }
            Button("Gruppe aus anderem Vertrag kopieren") { showCopyGroup = true }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showCopyGroup, onDismiss: loadGroups) {
            CopyArticleGroupSheet(currentContractId: contract.id) { groupIds in
                isCopyingGroups = true
                SupabaseManager.shared.copyArticleGroups(groupIds: groupIds, toContractId: contract.id) { result in
                    DispatchQueue.main.async {
                        isCopyingGroups = false
                        if case .failure(let err) = result { groupError = err.localizedDescription }
                        else { loadGroups() }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGroup) {
            AddArticleGroupSheet { name in
                SupabaseManager.shared.insertArticleGroup(fk_contract: contract.id, groupname: name.isEmpty ? nil : name) { result in
                    DispatchQueue.main.async {
                        if case .failure(let err) = result { groupError = err.localizedDescription }
                        else { loadGroups() }
                    }
                }
            }
        }
        .alert("Artikelgruppe löschen?", isPresented: Binding(
            get: { groupToDelete != nil },
            set: { if !$0 { groupToDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) { groupToDelete = nil }
            Button("Löschen", role: .destructive) {
                if let group = groupToDelete {
                    deleteGroup(group)
                }
                groupToDelete = nil
            }
        } message: {
            Text("Möchten Sie diese Artikelgruppe wirklich löschen?")
        }
    }
    
    @ViewBuilder
    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(Equans.Fonts.callout)
                .foregroundColor(Equans.Colors.textSecondary)
                .frame(width: 110, alignment: .leading)
            TextField(label, text: text)
                .font(Equans.Fonts.body)
                .foregroundColor(Equans.Colors.textPrimary)
        }
    }
    
    private func saveContract() {
        isSaving = true
        saveMessage = nil
        let fields = ContractUpdate(
            clientname: clientname.nilIfEmpty,
            contractname: contractname.nilIfEmpty,
            contractreference_1: reference1.nilIfEmpty,
            contractreference_2: reference2.nilIfEmpty,
            contractclientno: clientNo.nilIfEmpty,
            contractshortname: shortName.nilIfEmpty,
            contractclientdep: clientDep.nilIfEmpty,
            contractclientadress_1: address1.nilIfEmpty,
            contractclientadress_2: address2.nilIfEmpty,
            contractclientadress_zip: addressZip.nilIfEmpty,
            contractclientadress_city: addressCity.nilIfEmpty,
            contractstandardcostcenter: costCenter.nilIfEmpty
        )
        SupabaseManager.shared.updateContract(id: contract.id, fields: fields) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    saveMessage = "Gespeichert."
                    onChange()
                case .failure(let err):
                    saveMessage = "Fehler: \(err.localizedDescription)"
                }
            }
        }
    }
    
    private func loadGroups() {
        isLoadingGroups = true
        groupError = nil
        SupabaseManager.shared.fetchArticleGroups { result in
            DispatchQueue.main.async {
                isLoadingGroups = false
                switch result {
                case .success(let groups):
                    self.articleGroups = groups
                        .filter { $0.fk_contract == contract.id }
                        .sorted { ($0.groupname ?? "") < ($1.groupname ?? "") }
                case .failure(let err):
                    self.groupError = err.localizedDescription
                }
            }
        }
    }
    
    private func deleteGroup(_ group: ArticleGroup) {
        SupabaseManager.shared.deleteArticleGroup(id: group.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadGroups()
                case .failure(let err):
                    self.groupError = err.localizedDescription
                }
            }
        }
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct CopyArticleGroupSheet: View {
    let currentContractId: Int64
    var onCopy: ([Int64]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var contracts: [Contract] = []
    @State private var selectedContract: Contract? = nil
    @State private var groups: [ArticleGroup] = []
    @State private var selectedGroupIds: Set<Int64> = []
    @State private var isLoadingContracts = true
    @State private var isLoadingGroups = false
    @State private var searchText = ""

    private var filteredContracts: [Contract] {
        guard !searchText.isEmpty else { return contracts }
        return contracts.filter {
            ($0.contractname ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.clientname ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if selectedContract == nil {
                    // Schritt 1: Quell-Vertrag wählen
                    Group {
                        if isLoadingContracts {
                            ProgressView("Lade Verträge…").frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredContracts) { contract in
                                    Button(action: { selectContract(contract) }) {
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
                            .searchable(text: $searchText, prompt: "Vertrag suchen…")
                        }
                    }
                    .navigationTitle("Quell-Vertrag wählen")
                } else {
                    // Schritt 2: Gruppen auswählen
                    Group {
                        if isLoadingGroups {
                            ProgressView("Lade Gruppen…").frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if groups.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 36))
                                    .foregroundColor(Equans.Colors.border)
                                Text("Keine Artikelgruppen in diesem Vertrag.")
                                    .font(Equans.Fonts.callout)
                                    .foregroundColor(Equans.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                Section(footer: Text("Mehrfachauswahl möglich").font(Equans.Fonts.caption).foregroundColor(Equans.Colors.textSecondary)) {
                                    ForEach(groups) { group in
                                        Button(action: { toggle(group) }) {
                                            HStack {
                                                Image(systemName: selectedGroupIds.contains(group.id) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(selectedGroupIds.contains(group.id) ? Equans.Colors.darkGreen : Equans.Colors.border)
                                                    .font(.system(size: 22))
                                                Text(group.groupname ?? "(kein Name)")
                                                    .font(Equans.Fonts.body)
                                                    .foregroundColor(Equans.Colors.textPrimary)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                        .listRowBackground(Equans.Colors.surface)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .navigationTitle("Gruppen auswählen")
                }
            }
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedContract != nil {
                        Button("Zurück") { selectedContract = nil; selectedGroupIds = [] }
                            .foregroundColor(Equans.Colors.darkBlue)
                    } else {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                }
                if selectedContract != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kopieren (\(selectedGroupIds.count))") {
                            onCopy(Array(selectedGroupIds))
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Equans.Colors.darkBlue)
                        .disabled(selectedGroupIds.isEmpty)
                    }
                }
            }
        }
        .onAppear { loadContracts() }
    }

    private func toggle(_ group: ArticleGroup) {
        if selectedGroupIds.contains(group.id) { selectedGroupIds.remove(group.id) }
        else { selectedGroupIds.insert(group.id) }
    }

    private func selectContract(_ contract: Contract) {
        selectedContract = contract
        selectedGroupIds = []
        isLoadingGroups = true
        SupabaseManager.shared.fetchArticleGroups(forContract: contract.id) { result in
            DispatchQueue.main.async {
                isLoadingGroups = false
                if case .success(let g) = result {
                    groups = g.sorted { ($0.groupname ?? "") < ($1.groupname ?? "") }
                }
            }
        }
    }

    private func loadContracts() {
        isLoadingContracts = true
        SupabaseManager.shared.fetchContracts { result in
            DispatchQueue.main.async {
                isLoadingContracts = false
                if case .success(let all) = result {
                    contracts = all
                        .filter { $0.id != currentContractId }
                        .sorted { ($0.clientname ?? "") < ($1.clientname ?? "") }
                }
            }
        }
    }
}

private struct AddArticleGroupSheet: View {
    var onSave: (_ name: String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Artikelgruppe")) {
                    TextField("Gruppenname", text: $groupName)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Neue Artikelgruppe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Equans.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        onSave(groupName.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Equans.Colors.darkBlue)
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
