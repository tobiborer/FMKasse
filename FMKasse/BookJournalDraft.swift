import Foundation
import SwiftUI

class BookJournalDraft: ObservableObject, Identifiable {
    let id = UUID()
    @Published var fk_contract: Int64
    @Published var fk_machine: Int64?
    @Published var bookreference1: String?
    @Published var bookreference2: String?
    @Published var fk_objectorigin: Int64?
    @Published var fk_objectdestination: Int64?
    @Published var fk_order: Int64?
    @Published var contract: Contract
    @Published var machine: Machine?

    init(
        fk_contract: Int64,
        fk_machine: Int64? = nil,
        bookreference1: String? = nil,
        bookreference2: String? = nil,
        fk_objectorigin: Int64? = nil,
        fk_objectdestination: Int64? = nil,
        fk_order: Int64? = nil,
        contract: Contract,
        machine: Machine? = nil
    ) {
        self.fk_contract = fk_contract
        self.fk_machine = fk_machine
        self.bookreference1 = bookreference1
        self.bookreference2 = bookreference2
        self.fk_objectorigin = fk_objectorigin
        self.fk_objectdestination = fk_objectdestination
        self.fk_order = fk_order
        self.contract = contract
        self.machine = machine
    }
}
