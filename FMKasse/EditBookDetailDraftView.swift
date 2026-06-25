import SwiftUI

struct EditBookDetailDraftView: View {
    let article: Article
    @State var amount: String
    @State var price: String
    @State var description: String
    var onSave: (_ amount: Double, _ price: Double, _ description: String) -> Void
    var onCancel: () -> Void
    
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Artikel")) {
                    Text(article.articletitle ?? "")
                        .font(Equans.Fonts.headline)
                        .foregroundColor(Equans.Colors.textPrimary)
                    if let descr = article.articledescr, !descr.isEmpty {
                        Text(descr)
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                }
                Section(header: Text("Menge")) {
                    TextField("Menge", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                        .focused($isAmountFocused)
                        .onChange(of: isAmountFocused) { _, focused in
                            if focused && amount == "1" {
                                amount = ""
                            }
                        }
                }
                Section(header: Text("Preis")) {
                    TextField("Preis", text: $price)
                        .keyboardType(.decimalPad)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
                Section(header: Text("Beschreibung")) {
                    TextField("Beschreibung", text: $description)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationBarTitle("Artikeldetails", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Buchen") {
                        let effectiveAmount = amount.isEmpty ? "1" : amount
                        if let amountVal = Double(effectiveAmount), let priceVal = Double(price) {
                            onSave(amountVal, priceVal, description)
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Equans.Colors.darkBlue)
                    .disabled(Double(price) == nil)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAmountFocused = true
            }
        }
    }
}

// Preview
struct EditBookDetailDraftView_Previews: PreviewProvider {
    static var previews: some View {
        EditBookDetailDraftView(
            article: Article(id: 1, created_at: "", fk_articlegroup: 1, articletitle: "Testartikel", articledescr: "Beschreibung", articleunit: "Stk", articlerate: 9.99, articletax: 7.7),
            amount: "1",
            price: "9.99",
            description: "",
            onSave: {_,_,_ in},
            onCancel: {}
        )
    }
}
