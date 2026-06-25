import Foundation

struct BookDetailDraft: Identifiable {
    var id = UUID()
    var fk_article: Int64?
    var articletitle: String?
    var bookdetaildescr: String?
    var booknbrsarticle: Double?
    var bookdetailprice: Double?
}
