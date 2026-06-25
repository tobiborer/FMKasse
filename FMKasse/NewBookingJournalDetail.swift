import SwiftUI

struct NewBookingJournalDetail: View {
    let journal: BookJournal
    let contract: Contract
    @State private var bookDetails: [BookDetail] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var machineName: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Titel oben
            Text("Buchung \(journal.id) (Vertrag: \(contract.clientname ?? "-") / \(contract.contractname ?? "-"))")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .padding(.horizontal)
            Spacer().frame(height: 8)

            // Oberer Teil: BookJournal Felder
            VStack(alignment: .leading, spacing: 8) {
                Text("Kunde: \(contract.clientname ?? "-")")
                Text("Vertrag: \(contract.contractname ?? "-")")
                Text("Kasse: \(machineName ?? (journal.fk_machine != nil ? "#\(journal.fk_machine!)" : "-"))")
                if let ref1 = journal.bookreference1 { Text("Kostenstelle: \(ref1)") }
                if let ref2 = journal.bookreference2 { Text("Kundenreferenz (Bestellnummer): \(ref2)") }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding([.top, .horizontal])
            
            Divider().padding(.vertical, 8)
            
            // Unterer Teil: BookDetail-Liste
            VStack(alignment: .leading, spacing: 8) {
                Text("Positionen")
                    .font(.headline)
                if isLoading {
                    ProgressView("Lade Positionen...")
                } else if let error = error {
                    Text("Fehler: \(error)").foregroundColor(.red)
                } else if bookDetails.isEmpty {
                    Text("Keine Positionen gefunden.").foregroundColor(.secondary)
                } else {
                    List(bookDetails) { detail in
                        VStack(alignment: .leading) {
                            Text("ID: \(detail.id)")
                            if let descr = detail.bookdetaildescr { Text(descr).font(.subheadline) }
                            if let article = detail.fk_article { Text("Artikel-ID: \(article)") }
                            if let amount = detail.booknbrsarticle { Text("Menge: \(amount)") }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .padding([.horizontal, .bottom])
        }
        .onAppear {
            loadBookDetails()
            loadMachineName()
        }
    }
    
    private func loadBookDetails() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchBookDetails { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let allDetails):
                    self.bookDetails = allDetails.filter { $0.fk_bookjournal == journal.id }
                    self.isLoading = false
                case .failure(let err):
                    self.error = err.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    private func loadMachineName() {
        guard let machineId = journal.fk_machine else { return }
        SupabaseManager.shared.fetchMachines { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let machines):
                    self.machineName = machines.first(where: { $0.id == machineId })?.machinename
                case .failure:
                    self.machineName = nil
                }
            }
        }
    }
}

// Vorschau
struct NewBookingJournalDetail_Previews: PreviewProvider {
    static var previews: some View {
        let journal = BookJournal(
            id: 1,
            created_at: "2025-07-24T12:00:00Z",
            fk_machine: 2,
            fk_contract: 3,
            bookreference1: "Ref1",
            bookreference2: "Ref2",
            fk_objectorigin: nil,
            fk_objectdestination: nil,
            fk_order: nil
        )
        let contract = Contract(
            id: 3,
            created_at: "2025-07-24T12:00:00Z",
            clientname: "Musterkunde",
            contractname: "Vertrag A",
            contractdate: nil,
            contractvalid: nil,
            contractlogo: nil,
            contractreference_1: nil,
            contractreference_2: nil,
            contractreference_3: nil,
            contractreference_4: nil,
            contractclientno: nil,
            contractshortname: nil,
            contractclientdep: nil,
            contractclientadress_1: nil,
            contractclientadress_2: nil,
            contractclientadress_zip: nil,
            contractclientadress_city: nil,
            contractclienttaxid: nil,
            contractstandardcostcenter: nil,
            needobjectdefinition: nil,
            needplanonrderdefinition: nil,
            contractplanonref: nil,
            contractplanonreference_syscode: nil,
            contractsapobjectlink: nil,
            contractowner: nil
        )
        NewBookingJournalDetail(journal: journal, contract: contract)
    }
}
