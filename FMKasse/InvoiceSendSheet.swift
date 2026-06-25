import SwiftUI

struct InvoiceSendSheet: View {
    let item: InvoiceItem
    let contract: Contract?
    let periodLabel: String
    let lines: [InvoiceLine]
    var onDismiss: () -> Void

    @State private var recipient: String = ""
    @State private var isSending = false
    @State private var resultMessage: String?
    @State private var didSucceed = false

    private static let lastEmailKey = "lastInvoiceEmail"

    private var billingAddress: [String] {
        guard let c = contract else { return [] }
        var lines: [String] = []
        if let dep = c.contractclientdep, !dep.isEmpty { lines.append(dep) }
        if let a1 = c.contractclientadress_1, !a1.isEmpty { lines.append(a1) }
        if let a2 = c.contractclientadress_2, !a2.isEmpty { lines.append(a2) }
        let zipCity = [c.contractclientadress_zip, c.contractclientadress_city]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        if !zipCity.isEmpty { lines.append(zipCity) }
        return lines
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Empfänger")) {
                    TextField("E-Mail-Adresse", text: $recipient)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Rechnungsbeilage")) {
                    LabeledContent("Kunde", value: item.clientname)
                    LabeledContent("Vertrag", value: item.contractname)
                    LabeledContent("Periode", value: periodLabel)
                    LabeledContent("Betrag", value: formatCHF(item.totalValue))
                    LabeledContent("Positionen", value: "\(item.positionCount)")
                }

                if !billingAddress.isEmpty {
                    Section(header: Text("Rechnungsadresse")) {
                        ForEach(billingAddress, id: \.self) { line in
                            Text(line).font(.subheadline)
                        }
                    }
                }

                if let resultMessage = resultMessage {
                    Section {
                        Text(resultMessage)
                            .foregroundColor(didSucceed ? Equans.Colors.darkGreen : Equans.Colors.danger)
                            .font(Equans.Fonts.callout)
                    }
                }

            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Versenden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") { onDismiss() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
            }
            .onAppear {
                if recipient.isEmpty {
                    recipient = UserDefaults.standard.string(forKey: Self.lastEmailKey) ?? ""
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    Button(action: send) {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Label("Rechnungsbeilage per Mail versenden", systemImage: "paperplane.fill")
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(EquansPrimaryButtonStyle())
                    .disabled(isSending || !isValidEmail(recipient))
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Equans.Colors.background)
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    private func send() {
        let target = recipient.trimmingCharacters(in: .whitespaces)
        guard isValidEmail(target) else { return }
        isSending = true
        resultMessage = nil

        UserDefaults.standard.set(target, forKey: Self.lastEmailKey)

        let input = InvoicePDFInput(
            clientName: item.clientname,
            contractName: item.contractname,
            billingAddress: billingAddress,
            clientNo: contract?.contractclientno,
            costCenter: contract?.contractstandardcostcenter,
            periodLabel: periodLabel,
            lines: lines,
            total: item.totalValue,
            totalPositions: item.positionCount,
            totalBookings: item.journalCount
        )
        let pdfData = InvoicePDFGenerator.generate(input)
        let safeName = item.clientname
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let fileName = "Rechnungsbeilage_\(safeName).pdf"
        let subject = "Rechnungsbeilage \(item.clientname) – \(periodLabel)"
        let body = """
        Sehr geehrte Damen und Herren,

        im Anhang erhalten Sie die Rechnungsbeilage für \(item.contractname) (Periode: \(periodLabel)).

        Freundliche Grüsse
        EQUANS – FM Kasse
        """

        Task {
            do {
                try await SupabaseManager.shared.sendInvoiceEmail(
                    to: target,
                    subject: subject,
                    body: body,
                    pdfData: pdfData,
                    fileName: fileName
                )
                await MainActor.run {
                    isSending = false
                    didSucceed = true
                    resultMessage = "Rechnungsbeilage erfolgreich an \(target) versendet."
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    didSucceed = false
                    resultMessage = "Fehler beim Versand: \(error.localizedDescription)"
                }
            }
        }
    }
}
