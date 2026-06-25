import Foundation

struct BookJournalAgg: Identifiable, Codable {
    let journal_id: Int64
    let created_at: String
    let fk_contract: Int64?
    let fk_machine: Int64?
    let bookreference1: String?
    let bookreference2: String?
    let contractname: String?
    let clientname: String?
    let position_count: Int
    let total_value: Double
    
    var id: Int64 { journal_id }
    
    var created_atString: String {
        guard let date = ReportDateParser.parse(created_at) else {
            return created_at
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_CH")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}
