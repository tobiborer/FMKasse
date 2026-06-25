import SwiftUI

struct AddMachineView: View {
    var onDone: (Machine) -> Void

    @Environment(\.dismiss) private var dismiss

    // Step 1
    @State private var machineName = ""
    @State private var machineLocation = ""
    @State private var isSaving = false
    @State private var saveError: String?

    // Step 2
    @State private var createdMachine: Machine? = nil
    @State private var contracts: [Contract] = []
    @State private var articleGroups: [ArticleGroup] = []
    @State private var machineConfigs: [MachineConfig] = []
    @State private var isLoadingGroups = false
    @State private var expandedContractIds: Set<Int64> = []
    @State private var processingGroupId: Int64? = nil
    @State private var groupError: String? = nil

    var body: some View {
        NavigationView {
            Group {
                if createdMachine == nil {
                    step1
                } else {
                    step2
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if createdMachine == nil {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if createdMachine != nil {
                        Button("Fertig") {
                            if let machine = createdMachine { onDone(machine) }
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Equans.Colors.darkBlue)
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Kasse anlegen

    private var step1: some View {
        Form {
            Section(header: Text("Neue Kasse")) {
                HStack {
                    Image(systemName: "desktopcomputer")
                        .foregroundColor(Equans.Colors.darkBlue)
                        .frame(width: 24)
                    TextField("Name (z.B. Kasse 1)", text: $machineName)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Equans.Colors.textSecondary)
                        .frame(width: 24)
                    TextField("Standort (optional)", text: $machineLocation)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
            }

            if let saveError = saveError {
                Section {
                    Text(saveError)
                        .foregroundColor(Equans.Colors.danger)
                        .font(Equans.Fonts.caption)
                }
            }

            Section {
                Button(action: createMachine) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                        }
                        Text(isSaving ? "Wird erstellt…" : "Kasse erstellen")
                            .font(Equans.Fonts.roboto(16, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(machineName.trimmingCharacters(in: .whitespaces).isEmpty ? Equans.Colors.border : Equans.Colors.darkGreen)
                }
                .disabled(machineName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Equans.Colors.background.ignoresSafeArea())
        .navigationTitle("Neue Kasse")
    }

    // MARK: - Step 2: Artikelgruppen zuordnen

    private var step2: some View {
        Form {
            Section(header: Text("Kasse")) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Equans.Colors.darkGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(createdMachine?.machinename ?? "")
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                        if let loc = createdMachine?.machinelocation, !loc.isEmpty {
                            Text(loc)
                                .font(Equans.Fonts.caption)
                                .foregroundColor(Equans.Colors.textSecondary)
                        }
                    }
                }
            }

            Section(header: Text("Artikelgruppen zuordnen")) {
                if isLoadingGroups {
                    ProgressView("Lade Daten…")
                } else if contracts.isEmpty {
                    Text("Keine Verträge gefunden.")
                        .foregroundColor(Equans.Colors.textSecondary)
                        .font(Equans.Fonts.callout)
                } else {
                    ForEach(contracts) { contract in
                        contractSection(contract)
                    }
                }
                if let groupError = groupError {
                    Text(groupError)
                        .foregroundColor(Equans.Colors.danger)
                        .font(Equans.Fonts.caption)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Equans.Colors.background.ignoresSafeArea())
        .navigationTitle("Artikelgruppen")
        .onAppear(perform: loadGroupData)
    }

    @ViewBuilder
    private func contractSection(_ contract: Contract) -> some View {
        let groups = articleGroups.filter { $0.fk_contract == contract.id }
        let assignedCount = groups.filter { isGroupAssigned($0) }.count
        let isExpanded = expandedContractIds.contains(contract.id)

        VStack(spacing: 0) {
            Button(action: {
                if isExpanded { expandedContractIds.remove(contract.id) }
                else { expandedContractIds.insert(contract.id) }
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
                    if !groups.isEmpty {
                        Text("\(assignedCount)/\(groups.count)")
                            .font(Equans.Fonts.roboto(13, weight: .bold))
                            .foregroundColor(assignedCount == groups.count ? Equans.Colors.darkGreen : Equans.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                if groups.isEmpty {
                    Text("Keine Artikelgruppen vorhanden.")
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

    // MARK: - Logic

    private func createMachine() {
        let name = machineName.trimmingCharacters(in: .whitespaces)
        let location = machineLocation.trimmingCharacters(in: .whitespaces)
        isSaving = true
        saveError = nil
        SupabaseManager.shared.insertMachine(name: name, location: location.isEmpty ? nil : location) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success(let machine):
                    createdMachine = machine
                case .failure(let err):
                    saveError = err.localizedDescription
                }
            }
        }
    }

    private func loadGroupData() {
        isLoadingGroups = true
        let group = DispatchGroup()
        group.enter()
        SupabaseManager.shared.fetchContracts { result in
            DispatchQueue.main.async {
                if case .success(let c) = result {
                    contracts = c.sorted { ($0.clientname ?? "") < ($1.clientname ?? "") }
                    expandedContractIds = Set(c.map { $0.id })
                }
                group.leave()
            }
        }
        group.enter()
        SupabaseManager.shared.fetchArticleGroups { result in
            DispatchQueue.main.async {
                if case .success(let g) = result { articleGroups = g }
                group.leave()
            }
        }
        group.notify(queue: .main) { isLoadingGroups = false }
    }

    private func isGroupAssigned(_ group: ArticleGroup) -> Bool {
        guard let machineId = createdMachine?.id else { return false }
        return machineConfigs.contains { $0.fk_machine == machineId && $0.fk_articlegroup == group.id }
    }

    private func toggleGroup(_ group: ArticleGroup, currentlyAssigned: Bool) {
        guard let machineId = createdMachine?.id else { return }
        processingGroupId = group.id
        groupError = nil
        if currentlyAssigned {
            guard let config = machineConfigs.first(where: { $0.fk_machine == machineId && $0.fk_articlegroup == group.id }) else {
                processingGroupId = nil
                return
            }
            SupabaseManager.shared.deleteMachineConfig(id: config.id) { result in
                DispatchQueue.main.async {
                    if case .failure(let err) = result { groupError = err.localizedDescription }
                    reloadConfigs()
                }
            }
        } else {
            SupabaseManager.shared.insertMachineConfig(fk_machine: machineId, fk_articlegroup: group.id) { result in
                DispatchQueue.main.async {
                    if case .failure(let err) = result { groupError = err.localizedDescription }
                    reloadConfigs()
                }
            }
        }
    }

    private func reloadConfigs() {
        SupabaseManager.shared.fetchMachineConfigs { result in
            DispatchQueue.main.async {
                if case .success(let configs) = result { machineConfigs = configs }
                processingGroupId = nil
            }
        }
    }
}
