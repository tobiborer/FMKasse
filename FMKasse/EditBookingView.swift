import SwiftUI

struct EditBookingView: View {
    let entry: BookJournalAgg
    @State private var bookDetails: [BookDetail] = []
    @State private var articles: [Article] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var machineName: String? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showAddPosition = false
    @State private var draftDetails: [BookDetailDraft] = []
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isDeleting = false
    @State private var editingDetail: BookDetail? = nil
    @State private var detailToDelete: BookDetail? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Titel-Header
            Text("Buchung bearbeiten")
                .font(Equans.Fonts.headline)
                .foregroundColor(Equans.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Equans.Colors.surface)

            ScrollView {
                VStack(spacing: 16) {
                    // Buchungskopf
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buchung #\(entry.journal_id)")
                            .font(Equans.Fonts.title)
                            .foregroundColor(Equans.Colors.textPrimary)

                        infoRow("Kunde:", entry.clientname ?? "-")
                        infoRow("Vertrag:", entry.contractname ?? "-")
                        infoRow("Kasse:", machineName ?? (entry.fk_machine != nil ? "#\(entry.fk_machine!)" : "-"))

                        if let ref = entry.bookreference1, !ref.isEmpty {
                            infoRow("Referenz 1:", ref)
                        }
                        if let ref = entry.bookreference2, !ref.isEmpty {
                            infoRow("Referenz 2:", ref)
                        }

                        infoRow("Positionen:", "\(entry.position_count)")
                        infoRow("Gesamtwert:", String(format: "%.2f CHF", entry.total_value), bold: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Equans.Colors.surface)
                    .cornerRadius(Equans.Layout.cardRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                            .stroke(Equans.Colors.border, lineWidth: 1)
                    )
                    .padding(.horizontal)

                    Divider()

                    // Positionen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Positionen")
                            .font(Equans.Fonts.headline)
                            .foregroundColor(Equans.Colors.textPrimary)
                            .padding(.horizontal)

                        if isLoading {
                            ProgressView("Lade Positionen...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = error {
                            Text("Fehler: \(error)")
                                .foregroundColor(Equans.Colors.danger)
                                .padding()
                        } else if bookDetails.isEmpty {
                            Text("Keine Positionen gefunden.")
                                .foregroundColor(Equans.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(bookDetails) { detail in
                                positionRow(detail: detail)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }

            // Buttons
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Schließen")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Equans.Colors.textSecondary)
                            .foregroundColor(.white)
                            .cornerRadius(Equans.Layout.cornerRadius)
                    }

                    Button(action: { checkAndDeleteBooking() }) {
                        Text("Löschen")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Equans.Colors.danger)
                            .foregroundColor(.white)
                            .cornerRadius(Equans.Layout.cornerRadius)
                    }
                    .disabled(isDeleting)
                }

                Button(action: { showAddPosition = true }) {
                    Text("Position hinzufügen")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Equans.Colors.darkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(Equans.Layout.cornerRadius)
                }
            }
            .padding()
            .font(Equans.Fonts.roboto(16, weight: .bold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Equans.Colors.background)
        .ignoresSafeArea(.container, edges: .bottom)
        .alert("Buchung löschen?", isPresented: $showDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deleteBooking()
            }
        } message: {
            Text("Möchten Sie diese Buchung wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Fehler", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
        .onAppear {
            loadBookDetails()
            loadMachineName()
            loadArticles()
        }
        .fullScreenCover(isPresented: $showAddPosition) {
            if let contractId = entry.fk_contract, let machineId = entry.fk_machine {
                AddBookDetailToExistingJournalView(
                    journalId: entry.journal_id,
                    contractId: contractId,
                    machineId: machineId,
                    onComplete: {
                        showAddPosition = false
                        loadBookDetails()
                    },
                    onCancel: {
                        showAddPosition = false
                    }
                )
            }
        }
        .sheet(item: $editingDetail) { detail in
            EditPositionView(
                detail: detail,
                article: detail.fk_article.flatMap { id in articles.first(where: { $0.id == id }) },
                onSave: { amount, description in
                    updatePosition(detail: detail, amount: amount, description: description)
                    editingDetail = nil
                },
                onCancel: { editingDetail = nil }
            )
        }
        .alert("Position löschen?", isPresented: Binding(
            get: { detailToDelete != nil },
            set: { if !$0 { detailToDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) { detailToDelete = nil }
            Button("Löschen", role: .destructive) {
                if let detail = detailToDelete {
                    deletePosition(detail: detail)
                }
                detailToDelete = nil
            }
        } message: {
            Text("Möchten Sie diese Position wirklich löschen?")
        }
    }
    
    private func deletePosition(detail: BookDetail) {
        SupabaseManager.shared.deleteBookDetail(id: detail.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadBookDetails()
                case .failure(let err):
                    deleteErrorMessage = "Fehler beim Löschen der Position: \(err.localizedDescription)"
                    showDeleteError = true
                }
            }
        }
    }
    
    private func updatePosition(detail: BookDetail, amount: Double, description: String) {
        SupabaseManager.shared.updateBookDetail(
            id: detail.id,
            booknbrsarticle: amount,
            bookdetaildescr: description.isEmpty ? nil : description
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadBookDetails()
                case .failure(let err):
                    deleteErrorMessage = "Fehler beim Aktualisieren der Position: \(err.localizedDescription)"
                    showDeleteError = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func infoRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Equans.Fonts.callout)
                .frame(width: 110, alignment: .leading)
                .foregroundColor(Equans.Colors.textSecondary)
            Text(value)
                .font(Equans.Fonts.roboto(15, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? Equans.Colors.darkGreen : Equans.Colors.textPrimary)
            Spacer()
        }
    }

    @ViewBuilder
    private func positionRow(detail: BookDetail) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                if let articleId = detail.fk_article,
                   let article = articles.first(where: { $0.id == articleId }) {
                    Text(article.articletitle ?? "Artikel #\(articleId)")
                        .font(Equans.Fonts.headline)
                        .foregroundColor(Equans.Colors.textPrimary)
                    if let descr = detail.bookdetaildescr, !descr.isEmpty {
                        Text(descr)
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    HStack {
                        if let amount = detail.booknbrsarticle {
                            Text("Menge: \(String(format: "%.2f", amount))")
                                .font(Equans.Fonts.caption)
                                .foregroundColor(Equans.Colors.textSecondary)
                        }
                        Spacer()
                        if let rate = article.articlerate, let amount = detail.booknbrsarticle {
                            Text(String(format: "%.2f CHF", rate * amount))
                                .font(Equans.Fonts.roboto(13, weight: .bold))
                                .foregroundColor(Equans.Colors.darkGreen)
                        }
                    }
                } else {
                    Text("Position #\(detail.id)")
                        .font(Equans.Fonts.headline)
                        .foregroundColor(Equans.Colors.textPrimary)
                    if let descr = detail.bookdetaildescr {
                        Text(descr)
                            .font(Equans.Fonts.callout)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                    if let amount = detail.booknbrsarticle {
                        Text("Menge: \(String(format: "%.2f", amount))")
                            .font(Equans.Fonts.caption)
                            .foregroundColor(Equans.Colors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Button(action: { editingDetail = detail }) {
                    Image(systemName: "pencil")
                        .foregroundColor(Equans.Colors.darkBlue)
                        .frame(width: 32, height: 32)
                        .background(Equans.Colors.darkBlue.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: { detailToDelete = detail }) {
                    Image(systemName: "trash")
                        .foregroundColor(Equans.Colors.danger)
                        .frame(width: 32, height: 32)
                        .background(Equans.Colors.danger.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Equans.Colors.surface)
        .cornerRadius(Equans.Layout.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                .stroke(Equans.Colors.border, lineWidth: 1)
        )
    }

    private func loadBookDetails() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchBookDetails { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let allDetails):
                    self.bookDetails = allDetails.filter { $0.fk_bookjournal == entry.journal_id }
                    self.isLoading = false
                case .failure(let err):
                    self.error = err.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadMachineName() {
        guard let machineId = entry.fk_machine else { return }
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
    
    private func loadArticles() {
        SupabaseManager.shared.fetchArticles { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let articles):
                    self.articles = articles
                case .failure:
                    self.articles = []
                }
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Versuch 1: ISO8601 mit fractional seconds
        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: dateString) {
            return date
        }

        // Versuch 2: ISO8601 ohne fractional seconds
        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        if let date = isoStandard.date(from: dateString) {
            return date
        }

        // Versuch 3: DateFormatter mit verschiedenen Formaten
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    private func checkAndDeleteBooking() {
        // Parse das created_at Datum
        guard let bookingDate = parseDate(entry.created_at) else {
            deleteErrorMessage = "Fehler beim Lesen des Buchungsdatums: \(entry.created_at)"
            showDeleteError = true
            return
        }
        
        // Hole aktuelles Datum und Buchungsdatum
        let calendar = Calendar.current
        let now = Date()
        
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let bookingMonth = calendar.component(.month, from: bookingDate)
        let bookingYear = calendar.component(.year, from: bookingDate)
        
        // Prüfe ob im gleichen Monat
        if currentMonth == bookingMonth && currentYear == bookingYear {
            // Löschung ist erlaubt
            showDeleteConfirmation = true
        } else {
            // Löschung nicht erlaubt
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            deleteErrorMessage = "Diese Buchung vom \(dateFormatter.string(from: bookingDate)) kann nicht mehr gelöscht werden. Nur Buchungen aus dem aktuellen Monat können gelöscht werden."
            showDeleteError = true
        }
    }
    
    private func deleteBooking() {
        guard !isDeleting else { return }
        isDeleting = true
        
        // Erst die BookDetails löschen, dann das BookJournal
        SupabaseManager.shared.deleteBookDetails(forJournalId: entry.journal_id) { detailsResult in
            DispatchQueue.main.async {
                switch detailsResult {
                case .success:
                    // Details erfolgreich gelöscht, jetzt das Journal löschen
                    SupabaseManager.shared.deleteBookJournal(id: entry.journal_id) { journalResult in
                        DispatchQueue.main.async {
                            isDeleting = false
                            switch journalResult {
                            case .success:
                                // Erfolgreich gelöscht, schließe die View
                                NotificationCenter.default.post(name: .didCompleteTransaction, object: nil)
                                dismiss()
                            case .failure(let error):
                                deleteErrorMessage = "Fehler beim Löschen der Buchung: \(error.localizedDescription)"
                                showDeleteError = true
                            }
                        }
                    }
                case .failure(let error):
                    isDeleting = false
                    deleteErrorMessage = "Fehler beim Löschen der Positionen: \(error.localizedDescription)"
                    showDeleteError = true
                }
            }
        }
    }
}
