import SwiftUI

struct ArticleEditView: View {
    let article: Article?
    let groupId: Int64
    var onSave: () -> Void
    var onCancel: () -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var unit: String
    @State private var rate: String
    @State private var tax: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private var isEditing: Bool { article != nil }
    
    init(article: Article?, groupId: Int64, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.article = article
        self.groupId = groupId
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: article?.articletitle ?? "")
        _description = State(initialValue: article?.articledescr ?? "")
        _unit = State(initialValue: article?.articleunit ?? "")
        _rate = State(initialValue: article?.articlerate != nil ? String(format: "%.2f", article!.articlerate!) : "")
        _tax = State(initialValue: article?.articletax != nil ? String(format: "%.2f", article!.articletax!) : "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Artikel")) {
                    TextField("Titel", text: $title)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                    TextField("Beschreibung", text: $description, axis: .vertical)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                        .lineLimit(2, reservesSpace: true)
                    TextField("Einheit (z.B. Stk, h, kg)", text: $unit)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
                
                Section(header: Text("Preis & Steuer")) {
                    HStack {
                        Text("Preis")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                        Spacer()
                        TextField("0.00", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Equans.Colors.textPrimary)
                        Text("CHF").foregroundColor(Equans.Colors.textSecondary)
                    }
                    HStack {
                        Text("Steuer")
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                        Spacer()
                        TextField("0.00", text: $tax)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Equans.Colors.textPrimary)
                        Text("%").foregroundColor(Equans.Colors.textSecondary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section(header: Text("Fehler").foregroundColor(Equans.Colors.danger)) {
                        Text(errorMessage)
                            .foregroundColor(Equans.Colors.danger)
                            .font(Equans.Fonts.caption)
                            .textSelection(.enabled)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Artikel bearbeiten" : "Neuer Artikel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(Equans.Colors.darkBlue)
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        
        let rateValue = Double(rate.replacingOccurrences(of: ",", with: "."))
        let taxValue = Double(tax.replacingOccurrences(of: ",", with: "."))
        let titleValue = title.nilIfEmpty
        let descrValue = description.nilIfEmpty
        let unitValue = unit.nilIfEmpty
        
        let handler: (Result<Void, Error>) -> Void = { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    onSave()
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
        
        if let article = article {
            SupabaseManager.shared.updateArticle(
                id: article.id,
                articletitle: titleValue,
                articledescr: descrValue,
                articleunit: unitValue,
                articlerate: rateValue,
                articletax: taxValue,
                completion: handler
            )
        } else {
            SupabaseManager.shared.insertArticle(
                fk_articlegroup: groupId,
                articletitle: titleValue,
                articledescr: descrValue,
                articleunit: unitValue,
                articlerate: rateValue,
                articletax: taxValue,
                completion: handler
            )
        }
    }
}
