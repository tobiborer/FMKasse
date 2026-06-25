import SwiftUI

struct DraftSheetTestView: View {
    @StateObject var draft = BookJournalDraft(
        fk_contract: 1,
        contract: Contract(
            id: 1,
            created_at: "2025-01-01T00:00:00Z",
            clientname: "Demo-Kunde",
            contractname: "Demo-Vertrag",
            contractdate: nil,
            contractvalid: nil,
            contractlogo: nil,
            contractreference_1: "REF1",
            contractreference_2: "REF2",
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
    )
    @State private var showSheet = false
    @State private var draftDetails: [BookDetailDraft] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Draft: \(draft.bookreference1 ?? "-")")
            Button("Positionen hinzufügen") {
                showSheet = true
            }
        }
        .fullScreenCover(isPresented: $showSheet) {
            AddBookDetailDraftView(
                contract: draft.contract,
                machineId: draft.fk_machine ?? 0,
                draftDetails: $draftDetails,
                onCancel: { showSheet = false }
            )
        }
        .padding()
    }
}

struct DraftSheetTestView_Previews: PreviewProvider {
    static var previews: some View {
        DraftSheetTestView()
    }
}
