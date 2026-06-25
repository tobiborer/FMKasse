import SwiftUI

struct EditPositionView: View {
    let detail: BookDetail
    let article: Article?
    var onSave: (Double, String) -> Void
    var onCancel: () -> Void
    
    @State private var amount: String
    @State private var description: String
    @State private var showValidationError = false
    
    init(detail: BookDetail, article: Article?, onSave: @escaping (Double, String) -> Void, onCancel: @escaping () -> Void) {
        self.detail = detail
        self.article = article
        self.onSave = onSave
        self.onCancel = onCancel
        _amount = State(initialValue: detail.booknbrsarticle != nil ? String(format: "%.2f", detail.booknbrsarticle!) : "1")
        _description = State(initialValue: detail.bookdetaildescr ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Artikel")) {
                    Text(article?.articletitle ?? "Position #\(detail.id)")
                        .font(Equans.Fonts.headline)
                        .foregroundColor(Equans.Colors.textPrimary)
                    if let rate = article?.articlerate {
                        HStack {
                            Text("Einzelpreis")
                                .font(Equans.Fonts.callout)
                                .foregroundColor(Equans.Colors.textSecondary)
                            Spacer()
                            Text(String(format: "%.2f CHF", rate))
                                .font(Equans.Fonts.body)
                                .foregroundColor(Equans.Colors.textSecondary)
                        }
                    }
                }
                
                Section(header: Text("Menge")) {
                    TextField("Menge", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                }
                
                Section(header: Text("Beschreibung")) {
                    TextField("Beschreibung (optional)", text: $description, axis: .vertical)
                        .font(Equans.Fonts.body)
                        .foregroundColor(Equans.Colors.textPrimary)
                        .lineLimit(3, reservesSpace: true)
                }
                
                if let rate = article?.articlerate, let amountValue = parsedAmount {
                    Section(header: Text("Gesamt")) {
                        HStack {
                            Text("Gesamtpreis")
                                .font(Equans.Fonts.callout)
                                .foregroundColor(Equans.Colors.textSecondary)
                            Spacer()
                            Text(String(format: "%.2f CHF", rate * amountValue))
                                .font(Equans.Fonts.roboto(16, weight: .bold))
                                .foregroundColor(Equans.Colors.darkGreen)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Position bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        if let amountValue = parsedAmount, amountValue > 0 {
                            onSave(amountValue, description)
                        } else {
                            showValidationError = true
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Equans.Colors.darkBlue)
                }
            }
            .alert("Ungültige Menge", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Bitte geben Sie eine gültige Menge größer als 0 ein.")
            }
        }
    }
    
    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }
}
