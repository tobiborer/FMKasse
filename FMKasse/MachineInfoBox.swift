import SwiftUI

struct MachineInfoBox: View {
    @ObservedObject private var deviceRepo = DeviceRepository.shared
    @State private var machine: Machine?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        Group {
            if let machine = machine {
                let machineName = machine.machinename ?? "(kein Name)"
                let machineLocation = machine.machinelocation ?? "(kein Standort)"
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Equans.Colors.turquoise.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Equans.Colors.darkGreen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gerät #\(machine.id)")
                            .font(Equans.Fonts.roboto(15, weight: .bold))
                            .foregroundColor(Equans.Colors.textPrimary)
                        Text(machineName)
                            .font(Equans.Fonts.roboto(13, weight: .regular))
                            .foregroundColor(Equans.Colors.textSecondary)
                        Text(machineLocation)
                            .font(Equans.Fonts.roboto(11, weight: .regular))
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Equans.Colors.surface)
                .cornerRadius(Equans.Layout.cardRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                        .stroke(Equans.Colors.border, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
            } else if isLoading {
                ProgressView("Gerät wird geladen...")
                    .font(Equans.Fonts.body)
            } else if let error = error {
                Text("Fehler: \(error)")
                    .font(Equans.Fonts.caption)
                    .foregroundColor(Equans.Colors.danger)
            } else {
                Text("Kein Gerät zugewiesen.")
                    .font(Equans.Fonts.body)
                    .foregroundColor(Equans.Colors.textSecondary)
            }
        }
        .onAppear(perform: loadMachine)
        .onChange(of: deviceRepo.selectedMachineId) { oldValue, newValue in 
            loadMachine() 
        }
    }
    
    private func loadMachine() {
        guard let id = deviceRepo.selectedMachineId else {
            machine = nil
            return
        }
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchMachines { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let machines):
                    self.machine = machines.first(where: { $0.id == id })
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }
}
