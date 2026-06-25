import SwiftUI

struct SettingsMenuView: View {
    @ObservedObject private var deviceRepo = DeviceRepository.shared
    @State private var machines: [Machine] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedId: Int64?
    @Environment(\.dismiss) private var dismiss

    // Vertragszuordnung
    @State private var contracts: [Contract] = []
    @State private var articleGroups: [ArticleGroup] = []
    @State private var machineConfigs: [MachineConfig] = []
    @State private var isLoadingContracts = false
    @State private var contractError: String?
    @State private var processingGroupId: Int64? = nil
    @State private var expandedContractIds: Set<Int64> = []
    @State private var showAddMachine = false
    
    var body: some View {
        NavigationView {
            settingsForm
            .navigationTitle("Einstellungen")
            .onAppear {
                loadMachines()
                selectedId = deviceRepo.selectedMachineId
                loadContractData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showAddMachine = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Equans.Colors.darkGreen)
                        }
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Equans.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Settings Form
    private var settingsForm: some View {
        Form {
            Section(header: Text("Gerät zuweisen")) {
                if isLoading {
                    ProgressView("Lade Geräte...")
                } else if let error = error {
                    Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                } else {
                    Picker("Gerät", selection: $selectedId) {
                        ForEach(machines) { machine in
                            Text("\(machine.machinename ?? "(kein Name)") [\(machine.id)]").tag(machine.id as Int64?)
                        }
                    }
                    .onChange(of: selectedId) { oldValue, newValue in
                        deviceRepo.selectedMachineId = newValue
                        loadContractData()
                    }
                }
            }
            
            Section(header: Text("Artikelgruppen zuordnen")) {
                if deviceRepo.selectedMachineId == nil {
                    Text("Bitte zuerst ein Gerät auswählen.")
                        .foregroundColor(Equans.Colors.textSecondary)
                        .font(Equans.Fonts.callout)
                } else if isLoadingContracts {
                    ProgressView("Lade Verträge...")
                } else if let contractError = contractError {
                    Text("Fehler: \(contractError)").foregroundColor(Equans.Colors.danger)
                } else if contracts.isEmpty {
                    Text("Keine Verträge gefunden.")
                        .foregroundColor(Equans.Colors.textSecondary)
                        .font(Equans.Fonts.callout)
                } else {
                    ForEach(contracts) { contract in
                        contractSection(contract)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Equans.Colors.background.ignoresSafeArea())
        .sheet(isPresented: $showAddMachine) {
            AddMachineView { newMachine in
                machines.append(newMachine)
                selectedId = newMachine.id
                deviceRepo.selectedMachineId = newMachine.id
                loadContractData()
            }
        }
    }
    
    @ViewBuilder
    private func contractSection(_ contract: Contract) -> some View {
        let groups = articleGroups.filter { $0.fk_contract == contract.id }
        let assignedCount = groups.filter { isGroupAssigned($0) }.count
        let isExpanded = expandedContractIds.contains(contract.id)

        VStack(spacing: 0) {
            // Vertrag-Header (aufklappbar)
            Button(action: {
                if isExpanded {
                    expandedContractIds.remove(contract.id)
                } else {
                    expandedContractIds.insert(contract.id)
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Equans.Colors.textSecondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contract.clientname ?? "(kein Kunde)")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                        Text(contract.contractname ?? "(kein Vertrag)")
                            .font(Equans.Fonts.caption)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    Spacer()
                    if groups.isEmpty {
                        Text("Keine Gruppen")
                            .font(Equans.Fonts.caption)
                            .foregroundColor(Equans.Colors.textSecondary)
                    } else {
                        Text("\(assignedCount)/\(groups.count)")
                            .font(Equans.Fonts.roboto(13, weight: .bold))
                            .foregroundColor(assignedCount == groups.count ? Equans.Colors.darkGreen : Equans.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())

            // Artikelgruppen (ausgeklappt)
            if isExpanded {
                if groups.isEmpty {
                    Text("Dieser Vertrag hat keine Artikelgruppen.")
                        .font(Equans.Fonts.caption)
                        .foregroundColor(Equans.Colors.textSecondary)
                        .padding(.leading, 24)
                        .padding(.vertical, 6)
                } else {
                    ForEach(groups) { group in
                        articleGroupRow(group)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func articleGroupRow(_ group: ArticleGroup) -> some View {
        let assigned = isGroupAssigned(group)
        Button(action: { toggleGroup(group, currentlyAssigned: assigned) }) {
            HStack {
                Spacer().frame(width: 24)
                Text(group.groupname ?? "(keine Bezeichnung)")
                    .font(Equans.Fonts.callout)
                    .foregroundColor(Equans.Colors.textPrimary)
                Spacer()
                if processingGroupId == group.id {
                    ProgressView()
                } else if assigned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Equans.Colors.darkGreen)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Equans.Colors.border)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Group Logic
    private func isGroupAssigned(_ group: ArticleGroup) -> Bool {
        guard let machineId = deviceRepo.selectedMachineId else { return false }
        return machineConfigs.contains { $0.fk_machine == machineId && $0.fk_articlegroup == group.id }
    }

    private func toggleGroup(_ group: ArticleGroup, currentlyAssigned: Bool) {
        guard let machineId = deviceRepo.selectedMachineId else { return }
        processingGroupId = group.id
        if currentlyAssigned {
            guard let config = machineConfigs.first(where: { $0.fk_machine == machineId && $0.fk_articlegroup == group.id }) else {
                processingGroupId = nil
                return
            }
            SupabaseManager.shared.deleteMachineConfig(id: config.id) { result in
                DispatchQueue.main.async {
                    if case .failure(let err) = result { contractError = err.localizedDescription }
                    reloadMachineConfigs()
                }
            }
        } else {
            SupabaseManager.shared.insertMachineConfig(fk_machine: machineId, fk_articlegroup: group.id) { result in
                DispatchQueue.main.async {
                    if case .failure(let err) = result { contractError = err.localizedDescription }
                    reloadMachineConfigs()
                }
            }
        }
    }
    
    // MARK: - Loading
    private func loadMachines() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchMachines { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let machines):
                    self.machines = machines
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }
    
    private func loadContractData() {
        guard deviceRepo.selectedMachineId != nil else { return }
        isLoadingContracts = true
        contractError = nil
        let group = DispatchGroup()
        
        group.enter()
        SupabaseManager.shared.fetchContracts { result in
            DispatchQueue.main.async {
                if case .success(let contracts) = result {
                    self.contracts = contracts.sorted { ($0.clientname ?? "") < ($1.clientname ?? "") }
                } else if case .failure(let err) = result {
                    self.contractError = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        SupabaseManager.shared.fetchArticleGroups { result in
            DispatchQueue.main.async {
                if case .success(let groups) = result {
                    self.articleGroups = groups
                } else if case .failure(let err) = result {
                    self.contractError = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        SupabaseManager.shared.fetchMachineConfigs { result in
            DispatchQueue.main.async {
                if case .success(let configs) = result {
                    self.machineConfigs = configs
                } else if case .failure(let err) = result {
                    self.contractError = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoadingContracts = false
        }
    }
    
    private func reloadMachineConfigs() {
        SupabaseManager.shared.fetchMachineConfigs { result in
            DispatchQueue.main.async {
                if case .success(let configs) = result {
                    self.machineConfigs = configs
                }
                self.processingGroupId = nil
            }
        }
    }
}
