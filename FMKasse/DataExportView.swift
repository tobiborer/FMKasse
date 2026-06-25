import SwiftUI
import UIKit

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv   = "CSV"
    case excel = "Excel"
    case pdf   = "PDF"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .csv:   return "tablecells"
        case .excel: return "tablecells.fill"
        case .pdf:   return "doc.richtext.fill"
        }
    }

    var fileExtension: String {
        switch self { case .csv: return "csv"; case .excel: return "xml"; case .pdf: return "pdf" }
    }

    var description: String {
        switch self {
        case .csv:   return "Kommagetrennte Werte, öffnet in Excel/Numbers"
        case .excel: return "XML-Tabellenformat, direkt in Excel öffnen"
        case .pdf:   return "Formatierter Bericht als PDF"
        }
    }
}

// MARK: - Export Level

enum ExportLevel: String, CaseIterable, Identifiable {
    case buchung  = "Buchung"
    case position = "Position"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .buchung:  return "list.bullet.rectangle"
        case .position: return "list.bullet.indent"
        }
    }

    var description: String {
        switch self {
        case .buchung:  return "Zusammenfassung pro Buchung (Total & Anzahl Positionen)"
        case .position: return "Detailansicht mit allen Einzelpositionen"
        }
    }
}

// MARK: - Main View

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedContract: Contract? = nil
    @State private var selectedMachine: Machine?   = nil
    @State private var selectedPeriod: ReportPeriod = .currentMonth
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedLevel: ExportLevel  = .buchung
    @State private var recipientEmail = ""

    @State private var contracts:   [Contract]      = []
    @State private var machines:    [Machine]        = []
    @State private var aggs:        [BookJournalAgg] = []
    @State private var bookDetails: [BookDetail]     = []
    @State private var articles:    [Article]        = []
    @State private var isLoadingData = true

    @State private var isExporting   = false
    @State private var resultMessage: String?
    @State private var isSuccess     = false

    private var filteredAggs: [BookJournalAgg] {
        aggs.filter { agg in
            guard let date = ReportDateParser.parse(agg.created_at),
                  selectedPeriod.contains(date) else { return false }
            if let c = selectedContract, agg.fk_contract != c.id { return false }
            if let m = selectedMachine,  agg.fk_machine  != m.id { return false }
            return true
        }
    }

    private var filteredPositions: [PositionRow] {
        let journalIds = Set(filteredAggs.map { $0.journal_id })
        let articleMap = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        let aggMap     = Dictionary(uniqueKeysWithValues: filteredAggs.map { ($0.journal_id, $0) })
        return bookDetails
            .filter { d in d.fk_bookjournal.map { journalIds.contains($0) } ?? false }
            .map { d in
                let agg     = d.fk_bookjournal.flatMap { aggMap[$0] }
                let article = d.fk_article.flatMap { articleMap[$0] }
                let total   = (d.booknbrsarticle ?? 0) * (article?.articlerate ?? 0)
                return PositionRow(
                    detail:       d,
                    journalDate:  agg?.created_atString ?? "–",
                    clientname:   agg?.clientname ?? "–",
                    contractname: agg?.contractname ?? "–",
                    reference1:   agg?.bookreference1 ?? "–",
                    reference2:   agg?.bookreference2 ?? "–",
                    articleTitle: article?.articletitle ?? "–",
                    articleUnit:  article?.articleunit ?? "–",
                    articleRate:  article?.articlerate ?? 0,
                    quantity:     d.booknbrsarticle ?? 0,
                    lineTotal:    total
                )
            }
            .sorted { ($0.detail.fk_bookjournal ?? 0) < ($1.detail.fk_bookjournal ?? 0) }
    }

    private var totalAmount: Double { filteredAggs.reduce(0) { $0 + $1.total_value } }

    var body: some View {
        NavigationView {
            Form {
                // MARK: Filter
                Section("Filter") {
                    Picker("Periode", selection: $selectedPeriod) {
                        ForEach(ReportPeriod.allCases) { p in Text(p.rawValue).tag(p) }
                    }

                    Picker("Vertrag", selection: $selectedContract) {
                        Text("Alle Verträge").tag(nil as Contract?)
                        ForEach(contracts) { c in
                            Text("\(c.clientname ?? "") – \(c.contractname ?? "")").tag(c as Contract?)
                        }
                    }

                    Picker("Gerät", selection: $selectedMachine) {
                        Text("Alle Geräte").tag(nil as Machine?)
                        ForEach(machines) { m in
                            Text(m.machinename ?? "Gerät \(m.id)").tag(m as Machine?)
                        }
                    }
                }

                // MARK: Vorschau
                Section("Vorschau") {
                    if isLoadingData {
                        HStack { Spacer(); ProgressView("Lade Daten…"); Spacer() }
                    } else {
                        LabeledContent("Buchungen") { Text("\(filteredAggs.count)").foregroundColor(Equans.Colors.textPrimary) }
                        if selectedLevel == .position {
                            LabeledContent("Positionen") { Text("\(filteredPositions.count)").foregroundColor(Equans.Colors.textPrimary) }
                        }
                        LabeledContent("Gesamtbetrag") {
                            Text(formatCHF(totalAmount))
                                .fontWeight(.semibold)
                                .foregroundColor(Equans.Colors.darkGreen)
                        }
                    }
                }

                // MARK: Detailstufe
                Section("Detailstufe") {
                    ForEach(ExportLevel.allCases) { level in
                        Button(action: { selectedLevel = level }) {
                            HStack(spacing: 12) {
                                Image(systemName: level.icon)
                                    .foregroundColor(Equans.Colors.darkBlue)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.rawValue)
                                        .font(Equans.Fonts.body)
                                        .foregroundColor(Equans.Colors.textPrimary)
                                    Text(level.description)
                                        .font(Equans.Fonts.caption)
                                        .foregroundColor(Equans.Colors.textSecondary)
                                }
                                Spacer()
                                if selectedLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Equans.Colors.darkGreen)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // MARK: Format
                Section("Format") {
                    ForEach(ExportFormat.allCases) { fmt in
                        Button(action: { selectedFormat = fmt }) {
                            HStack(spacing: 12) {
                                Image(systemName: fmt.icon)
                                    .foregroundColor(Equans.Colors.darkBlue)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fmt.rawValue)
                                        .font(Equans.Fonts.body)
                                        .foregroundColor(Equans.Colors.textPrimary)
                                    Text(fmt.description)
                                        .font(Equans.Fonts.caption)
                                        .foregroundColor(Equans.Colors.textSecondary)
                                }
                                Spacer()
                                if selectedFormat == fmt {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Equans.Colors.darkGreen)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // MARK: Empfänger
                Section("Empfänger") {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Equans.Colors.textSecondary)
                        TextField("E-Mail Adresse", text: $recipientEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(Equans.Fonts.body)
                    }
                }

                // MARK: Statusmeldung
                if let msg = resultMessage {
                    Section {
                        Text(msg)
                            .font(Equans.Fonts.caption)
                            .foregroundColor(isSuccess ? Equans.Colors.darkGreen : Equans.Colors.danger)
                            .textSelection(.enabled)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .navigationTitle("Datenexport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(Equans.Colors.textSecondary)
                }
            }
            .onAppear(perform: loadData)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    Button(action: startExport) {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Exportieren & Versenden", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(EquansPrimaryButtonStyle())
                    .disabled(isExporting || recipientEmail.trimmingCharacters(in: .whitespaces).isEmpty
                              || isLoadingData || filteredAggs.isEmpty)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Equans.Colors.background)
                }
            }
        }
    }

    // MARK: - Load

    private func loadData() {
        isLoadingData = true
        let group = DispatchGroup()

        group.enter()
        SupabaseManager.shared.fetchContracts { result in
            if case .success(let c) = result {
                DispatchQueue.main.async { contracts = c.sorted { ($0.clientname ?? "") < ($1.clientname ?? "") } }
            }
            group.leave()
        }

        group.enter()
        SupabaseManager.shared.fetchMachines { result in
            if case .success(let m) = result {
                DispatchQueue.main.async { machines = m.sorted { ($0.machinename ?? "") < ($1.machinename ?? "") } }
            }
            group.leave()
        }

        group.enter()
        SupabaseManager.shared.fetchBookJournalAggs { result in
            if case .success(let a) = result { DispatchQueue.main.async { aggs = a } }
            group.leave()
        }

        group.enter()
        SupabaseManager.shared.fetchBookDetails { result in
            if case .success(let d) = result { DispatchQueue.main.async { bookDetails = d } }
            group.leave()
        }

        group.enter()
        SupabaseManager.shared.fetchArticles { result in
            if case .success(let a) = result { DispatchQueue.main.async { articles = a } }
            group.leave()
        }

        group.notify(queue: .main) { isLoadingData = false }
    }

    // MARK: - Export

    private func startExport() {
        isExporting   = true
        resultMessage = nil
        let email         = recipientEmail.trimmingCharacters(in: .whitespaces)
        let periodLabel   = selectedPeriod.rawValue
        let contractLabel = selectedContract.map { "\($0.clientname ?? "") – \($0.contractname ?? "")" } ?? "Alle Verträge"
        let machineLabel  = selectedMachine?.machinename ?? "Alle Geräte"
        let level         = selectedLevel
        let aggData       = filteredAggs
        let posData       = filteredPositions
        let total         = totalAmount

        Task {
            do {
                let (fileData, fileName) = try ExportGenerator.generate(
                    aggs: aggData,
                    positions: posData,
                    machines: machines,
                    format: selectedFormat,
                    level: level,
                    period: periodLabel,
                    contract: contractLabel,
                    machine: machineLabel
                )
                let stufe  = level == .buchung ? "Buchungsstufe" : "Positionsstufe"
                let subject = "FM Kasse Export (\(stufe)) – \(periodLabel) – \(contractLabel)"
                let body = """
                FM Kasse Datenexport (\(stufe))

                Periode:    \(periodLabel)
                Vertrag:    \(contractLabel)
                Gerät:      \(machineLabel)
                Buchungen:  \(aggData.count)
                Positionen: \(posData.count)
                Betrag:     \(formatCHF(total))
                """
                try await SupabaseManager.shared.sendInvoiceEmail(
                    to: email, subject: subject, body: body,
                    pdfData: fileData, fileName: fileName
                )
                await MainActor.run {
                    isExporting = false; isSuccess = true
                    resultMessage = "Export erfolgreich an \(email) versendet."
                }
            } catch {
                await MainActor.run {
                    isExporting = false; isSuccess = false
                    resultMessage = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - PositionRow

struct PositionRow {
    let detail:       BookDetail
    let journalDate:  String
    let clientname:   String
    let contractname: String
    let reference1:   String
    let reference2:   String
    let articleTitle: String
    let articleUnit:  String
    let articleRate:  Double
    let quantity:     Double
    let lineTotal:    Double
}

// MARK: - Generator

enum ExportGenerator {

    static func generate(
        aggs: [BookJournalAgg],
        positions: [PositionRow],
        machines: [Machine],
        format: ExportFormat,
        level: ExportLevel,
        period: String, contract: String, machine: String
    ) throws -> (Data, String) {
        let stamp = DateFormatter().apply {
            $0.dateFormat = "yyyyMMdd"
        }.string(from: Date())
        let levelSuffix = level == .position ? "_Positionen" : ""
        let fileName = "FMKasse_Export\(levelSuffix)_\(stamp).\(format.fileExtension)"

        switch (format, level) {
        case (.csv,   .buchung):  return (try csvBuchung(data: aggs), fileName)
        case (.csv,   .position): return (try csvPosition(data: positions), fileName)
        case (.excel, .buchung):  return (try excelBuchung(data: aggs, machines: machines, period: period, contract: contract, machine: machine), fileName)
        case (.excel, .position): return (try excelPosition(data: positions, period: period, contract: contract, machine: machine), fileName)
        case (.pdf,   .buchung):  return (try pdfBuchung(data: aggs, machines: machines, period: period, contract: contract, machine: machine), fileName)
        case (.pdf,   .position): return (try pdfPosition(data: positions, period: period, contract: contract, machine: machine), fileName)
        }
    }

    // MARK: CSV – Buchung

    private static func csvBuchung(data: [BookJournalAgg]) throws -> Data {
        let headers = ["ID", "Datum", "Kunde", "Vertrag", "Kostenstelle", "Kundenreferenz (Bestellnummer)", "Positionen", "Betrag CHF"]
        var rows: [[String]] = [headers]
        for a in data {
            rows.append([
                "\(a.journal_id)",
                a.created_atString,
                a.clientname ?? "",
                a.contractname ?? "",
                a.bookreference1 ?? "",
                a.bookreference2 ?? "",
                "\(a.position_count)",
                String(format: "%.2f", a.total_value)
            ])
        }
        let csv = "\u{FEFF}" + rows.map { row in
            row.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ";")
        }.joined(separator: "\n")
        guard let data = csv.data(using: .utf8) else {
            throw NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV-Encoding fehlgeschlagen"])
        }
        return data
    }

    // MARK: CSV – Position

    private static func csvPosition(data: [PositionRow]) throws -> Data {
        let headers = ["Buchungs-ID", "Datum", "Kunde", "Vertrag", "Kostenstelle", "Kundenreferenz (Bestellnummer)",
                       "Artikel", "Beschreibung", "Einheit", "Anzahl", "Einzelpreis CHF", "Betrag CHF"]
        var rows: [[String]] = [headers]
        for p in data {
            rows.append([
                "\(p.detail.fk_bookjournal ?? 0)",
                p.journalDate,
                p.clientname,
                p.contractname,
                p.reference1,
                p.reference2,
                p.articleTitle,
                p.detail.bookdetaildescr ?? "",
                p.articleUnit,
                String(format: "%.2f", p.quantity),
                String(format: "%.2f", p.articleRate),
                String(format: "%.2f", p.lineTotal)
            ])
        }
        let csv = "\u{FEFF}" + rows.map { row in
            row.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ";")
        }.joined(separator: "\n")
        guard let data = csv.data(using: .utf8) else {
            throw NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV-Encoding fehlgeschlagen"])
        }
        return data
    }

    // MARK: Excel (XML Spreadsheet 2003) – Buchung

    private static func excelBuchung(
        data: [BookJournalAgg], machines: [Machine],
        period: String, contract: String, machine: String
    ) throws -> Data {
        let machineMap = Dictionary(uniqueKeysWithValues: machines.map { ($0.id, $0.machinename ?? "–") })
        func esc(_ s: String) -> String { s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;") }
        func strCell(_ v: String) -> String { "<Cell><Data ss:Type=\"String\">\(esc(v))</Data></Cell>" }
        func numCell(_ v: Double) -> String { "<Cell><Data ss:Type=\"Number\">\(String(format: "%.2f", v))</Data></Cell>" }
        func intCell(_ v: Int) -> String { "<Cell><Data ss:Type=\"Number\">\(v)</Data></Cell>" }

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
                  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
                  xmlns:x="urn:schemas-microsoft-com:office:excel">
          <Styles>
            <Style ss:ID="header"><Font ss:Bold="1"/><Interior ss:Color="#008163" ss:Pattern="Solid"/><Font ss:Color="#FFFFFF" ss:Bold="1"/></Style>
            <Style ss:ID="total"><Font ss:Bold="1"/></Style>
          </Styles>
          <Worksheet ss:Name="Export">
            <Table>
              <Row>
                \(strCell("FM Kasse Export"))
              </Row>
              <Row>
                \(strCell("Periode: \(period)")) \(strCell("Vertrag: \(contract)")) \(strCell("Gerät: \(machine)"))
              </Row>
              <Row/>
              <Row ss:StyleID="header">
                \(strCell("ID"))\(strCell("Datum"))\(strCell("Kunde"))\(strCell("Vertrag"))\(strCell("Gerät"))\(strCell("Kostenstelle"))\(strCell("Kundenreferenz (Bestellnummer)"))\(strCell("Positionen"))\(strCell("Betrag CHF"))
              </Row>

        """
        var grandTotal = 0.0
        for a in data {
            let machineName = a.fk_machine.flatMap { machineMap[$0] } ?? "–"
            xml += """
              <Row>
                \(intCell(Int(a.journal_id)))\(strCell(a.created_atString))\(strCell(a.clientname ?? ""))\(strCell(a.contractname ?? ""))\(strCell(machineName))\(strCell(a.bookreference1 ?? ""))\(strCell(a.bookreference2 ?? ""))\(intCell(a.position_count))\(numCell(a.total_value))
              </Row>

            """
            grandTotal += a.total_value
        }
        xml += """
              <Row ss:StyleID="total">
                \(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell("Total"))\(intCell(data.reduce(0) { $0 + $1.position_count }))\(numCell(grandTotal))
              </Row>
            </Table>
          </Worksheet>
        </Workbook>
        """
        guard let d = xml.data(using: .utf8) else {
            throw NSError(domain: "Export", code: 2, userInfo: [NSLocalizedDescriptionKey: "Excel-Encoding fehlgeschlagen"])
        }
        return d
    }

    // MARK: Excel – Position

    private static func excelPosition(
        data: [PositionRow],
        period: String, contract: String, machine: String
    ) throws -> Data {
        func esc(_ s: String) -> String { s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;") }
        func strCell(_ v: String) -> String { "<Cell><Data ss:Type=\"String\">\(esc(v))</Data></Cell>" }
        func numCell(_ v: Double) -> String { "<Cell><Data ss:Type=\"Number\">\(String(format: "%.2f", v))</Data></Cell>" }

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
                  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
                  xmlns:x="urn:schemas-microsoft-com:office:excel">
          <Styles>
            <Style ss:ID="header"><Font ss:Bold="1"/><Interior ss:Color="#008163" ss:Pattern="Solid"/><Font ss:Color="#FFFFFF" ss:Bold="1"/></Style>
            <Style ss:ID="total"><Font ss:Bold="1"/></Style>
          </Styles>
          <Worksheet ss:Name="Positionen">
            <Table>
              <Row>\(strCell("FM Kasse Positionsexport"))</Row>
              <Row>\(strCell("Periode: \(period)")) \(strCell("Vertrag: \(contract)")) \(strCell("Gerät: \(machine)"))</Row>
              <Row/>
              <Row ss:StyleID="header">
                \(strCell("Buch.-ID"))\(strCell("Datum"))\(strCell("Kunde"))\(strCell("Vertrag"))\(strCell("Ref. 1"))\(strCell("Ref. 2"))\(strCell("Artikel"))\(strCell("Beschreibung"))\(strCell("Einheit"))\(strCell("Anzahl"))\(strCell("Einzelpreis"))\(strCell("Betrag CHF"))
              </Row>

        """
        var grandTotal = 0.0
        for p in data {
            xml += """
              <Row>
                \(strCell("\(p.detail.fk_bookjournal ?? 0)"))\(strCell(p.journalDate))\(strCell(p.clientname))\(strCell(p.contractname))\(strCell(p.reference1))\(strCell(p.reference2))\(strCell(p.articleTitle))\(strCell(p.detail.bookdetaildescr ?? ""))\(strCell(p.articleUnit))\(numCell(p.quantity))\(numCell(p.articleRate))\(numCell(p.lineTotal))
              </Row>

            """
            grandTotal += p.lineTotal
        }
        xml += """
              <Row ss:StyleID="total">
                \(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell(""))\(strCell("Total"))\(strCell(""))\(strCell(""))\(numCell(grandTotal))
              </Row>
            </Table>
          </Worksheet>
        </Workbook>
        """
        guard let d = xml.data(using: .utf8) else {
            throw NSError(domain: "Export", code: 2, userInfo: [NSLocalizedDescriptionKey: "Excel-Encoding fehlgeschlagen"])
        }
        return d
    }

    // MARK: PDF – Buchung

    private static func pdfBuchung(
        data: [BookJournalAgg], machines: [Machine],
        period: String, contract: String, machine: String
    ) throws -> Data {
        let machineMap = Dictionary(uniqueKeysWithValues: machines.map { ($0.id, $0.machinename ?? "–") })
        let pageW: CGFloat = 842; let pageH: CGFloat = 595  // A4 landscape
        let margin: CGFloat = 36

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageW, height: pageH), nil)

        let columns: [(title: String, width: CGFloat)] = [
            ("Datum",       110), ("Kunde",  130), ("Vertrag", 130),
            ("Gerät",        90), ("Ref. 1",  80), ("Ref. 2",  70),
            ("Pos.",         40), ("Betrag CHF", 82)
        ]
        let tableW = columns.reduce(0) { $0 + $1.width }
        let rowH: CGFloat = 18
        let headerH: CGFloat = 22
        let rowsPerPage = Int((pageH - margin * 2 - 60 - headerH) / rowH)

        let darkGreen = UIColor(red: 0, green: 0.506, blue: 0.388, alpha: 1)
        let lightGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)

        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.black]
        let subAttrs: [NSAttributedString.Key: Any]   = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray]
        let headerAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .semibold), .foregroundColor: UIColor.white]
        let cellAttrs: [NSAttributedString.Key: Any]   = [.font: UIFont.systemFont(ofSize: 8.5), .foregroundColor: UIColor.black]
        let totalAttrs: [NSAttributedString.Key: Any]  = [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: UIColor.black]

        var pageIndex = 0
        var rowIndex = 0

        func startPage() {
            UIGraphicsBeginPDFPage()
            let ctx = UIGraphicsGetCurrentContext()!

            // Title area
            "FM Kasse – Datenexport".draw(at: CGPoint(x: margin, y: margin), withAttributes: titleAttrs)
            let sub = "Periode: \(period)   |   Vertrag: \(contract)   |   Gerät: \(machine)   |   Buchungen: \(data.count)   |   Betrag: \(formatCHF(data.reduce(0) { $0 + $1.total_value }))"
            sub.draw(at: CGPoint(x: margin, y: margin + 22), withAttributes: subAttrs)

            let tableY = margin + 50.0
            // Header row
            ctx.setFillColor(darkGreen.cgColor)
            ctx.fill(CGRect(x: margin, y: tableY, width: tableW, height: headerH))
            var x = margin
            for col in columns {
                col.title.draw(in: CGRect(x: x + 3, y: tableY + 4, width: col.width - 6, height: headerH), withAttributes: headerAttrs)
                x += col.width
            }
        }

        func tableY(forRow row: Int) -> CGFloat { margin + 50 + headerH + CGFloat(row) * rowH }

        startPage()
        let ctx0 = UIGraphicsGetCurrentContext()!

        for (i, agg) in data.enumerated() {
            if rowIndex >= rowsPerPage {
                pageIndex += 1; rowIndex = 0
                startPage()
            }
            let y = tableY(forRow: rowIndex)
            let ctx = UIGraphicsGetCurrentContext()!
            if rowIndex % 2 == 1 {
                ctx.setFillColor(lightGray.cgColor)
                ctx.fill(CGRect(x: margin, y: y, width: tableW, height: rowH))
            }
            let machineName = agg.fk_machine.flatMap { machineMap[$0] } ?? "–"
            let values = [
                agg.created_atString, agg.clientname ?? "–", agg.contractname ?? "–",
                machineName, agg.bookreference1 ?? "–", agg.bookreference2 ?? "–",
                "\(agg.position_count)", String(format: "%.2f", agg.total_value)
            ]
            var x = margin
            for (ci, col) in columns.enumerated() {
                values[ci].draw(in: CGRect(x: x + 3, y: y + 3, width: col.width - 6, height: rowH - 4), withAttributes: cellAttrs)
                x += col.width
            }
            rowIndex += 1
        }

        // Total row
        let totalY = tableY(forRow: rowIndex)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(UIColor(white: 0.88, alpha: 1).cgColor)
        ctx.fill(CGRect(x: margin, y: totalY, width: tableW, height: rowH))
        let grandTotal = data.reduce(0) { $0 + $1.total_value }
        let totalPositions = data.reduce(0) { $0 + $1.position_count }
        let totalValues = ["", "", "", "", "", "Total", "\(totalPositions)", String(format: "%.2f", grandTotal)]
        var x2 = margin
        for (ci, col) in columns.enumerated() {
            totalValues[ci].draw(in: CGRect(x: x2 + 3, y: totalY + 3, width: col.width - 6, height: rowH - 4), withAttributes: totalAttrs)
            x2 += col.width
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: PDF – Position

    private static func pdfPosition(
        data: [PositionRow],
        period: String, contract: String, machine: String
    ) throws -> Data {
        let pageW: CGFloat = 842; let pageH: CGFloat = 595
        let margin: CGFloat = 36

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageW, height: pageH), nil)

        let columns: [(title: String, width: CGFloat)] = [
            ("Datum", 90), ("Kunde", 100), ("Vertrag", 100),
            ("Artikel", 100), ("Beschreibung", 110), ("Einheit", 50),
            ("Anzahl", 50), ("Preis CHF", 70), ("Betrag CHF", 72)
        ]
        let tableW   = columns.reduce(0) { $0 + $1.width }
        let rowH: CGFloat    = 18
        let headerH: CGFloat = 22
        let rowsPerPage = Int((pageH - margin * 2 - 60 - headerH) / rowH)

        let darkGreen = UIColor(red: 0, green: 0.506, blue: 0.388, alpha: 1)
        let lightGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)

        let titleAttrs:  [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .bold)]
        let subAttrs:    [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray]
        let headerAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .semibold), .foregroundColor: UIColor.white]
        let cellAttrs:   [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8.5)]
        let totalAttrs:  [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold)]

        var rowIndex = 0

        func startPage() {
            UIGraphicsBeginPDFPage()
            let ctx = UIGraphicsGetCurrentContext()!
            "FM Kasse – Positionsexport".draw(at: CGPoint(x: margin, y: margin), withAttributes: titleAttrs)
            let sub = "Periode: \(period)   |   Vertrag: \(contract)   |   Gerät: \(machine)   |   Positionen: \(data.count)   |   Betrag: \(formatCHF(data.reduce(0) { $0 + $1.lineTotal }))"
            sub.draw(at: CGPoint(x: margin, y: margin + 22), withAttributes: subAttrs)
            let tableY = margin + 50.0
            ctx.setFillColor(darkGreen.cgColor)
            ctx.fill(CGRect(x: margin, y: tableY, width: tableW, height: headerH))
            var x = margin
            for col in columns {
                col.title.draw(in: CGRect(x: x + 3, y: tableY + 4, width: col.width - 6, height: headerH), withAttributes: headerAttrs)
                x += col.width
            }
        }

        func tableY(forRow row: Int) -> CGFloat { margin + 50 + headerH + CGFloat(row) * rowH }

        startPage()

        for p in data {
            if rowIndex >= rowsPerPage { rowIndex = 0; startPage() }
            let y   = tableY(forRow: rowIndex)
            let ctx = UIGraphicsGetCurrentContext()!
            if rowIndex % 2 == 1 {
                ctx.setFillColor(lightGray.cgColor)
                ctx.fill(CGRect(x: margin, y: y, width: tableW, height: rowH))
            }
            let values = [
                p.journalDate, p.clientname, p.contractname,
                p.articleTitle, p.detail.bookdetaildescr ?? "–", p.articleUnit,
                String(format: "%.2f", p.quantity),
                String(format: "%.2f", p.articleRate),
                String(format: "%.2f", p.lineTotal)
            ]
            var x = margin
            for (ci, col) in columns.enumerated() {
                values[ci].draw(in: CGRect(x: x + 3, y: y + 3, width: col.width - 6, height: rowH - 4), withAttributes: cellAttrs)
                x += col.width
            }
            rowIndex += 1
        }

        let totalY  = tableY(forRow: rowIndex)
        let ctx     = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(UIColor(white: 0.88, alpha: 1).cgColor)
        ctx.fill(CGRect(x: margin, y: totalY, width: tableW, height: rowH))
        let grandTotal   = data.reduce(0) { $0 + $1.lineTotal }
        let totalValues  = ["", "", "", "", "", "", "", "Total", String(format: "%.2f", grandTotal)]
        var x2 = margin
        for (ci, col) in columns.enumerated() {
            totalValues[ci].draw(in: CGRect(x: x2 + 3, y: totalY + 3, width: col.width - 6, height: rowH - 4), withAttributes: totalAttrs)
            x2 += col.width
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}

// MARK: - Helpers

private extension DateFormatter {
    func apply(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self); return self
    }
}
