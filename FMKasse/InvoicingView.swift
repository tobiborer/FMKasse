import SwiftUI

struct InvoiceItem: Identifiable {
    let id = UUID()
    let clientname: String
    let contractname: String
    let fk_contract: Int64?
    let journalCount: Int
    let positionCount: Int
    let totalValue: Double
}

struct InvoicingView: View {
    @State private var aggs: [BookJournalAgg] = []
    @State private var contracts: [Contract] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var period: ReportPeriod = .currentMonth
    @State private var metric: StatMetric = .amount
    @State private var selectedItem: InvoiceItem?
    
    private func value(_ item: InvoiceItem) -> Double {
        switch metric {
        case .amount: return item.totalValue
        case .bookings: return Double(item.journalCount)
        case .positions: return Double(item.positionCount)
        }
    }
    
    private var filteredAggs: [BookJournalAgg] {
        aggs.filter { agg in
            guard let date = ReportDateParser.parse(agg.created_at) else { return period == .all }
            return period.contains(date)
        }
    }
    
    private var items: [InvoiceItem] {
        let grouped = Dictionary(grouping: filteredAggs) { agg in
            "\(agg.clientname ?? "(kein Kunde)")|\(agg.contractname ?? "(kein Vertrag)")"
        }
        return grouped.map { (_, group) in
            let first = group.first
            return InvoiceItem(
                clientname: first?.clientname ?? "(kein Kunde)",
                contractname: first?.contractname ?? "(kein Vertrag)",
                fk_contract: first?.fk_contract,
                journalCount: group.count,
                positionCount: group.reduce(0) { $0 + $1.position_count },
                totalValue: group.reduce(0) { $0 + $1.total_value }
            )
        }
        .sorted { value($0) > value($1) }
    }
    
    private var grandTotal: Double {
        items.reduce(0) { $0 + value($1) }
    }
    
    private var periodLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Zeitraum", selection: $period) {
                ForEach(ReportPeriod.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)
            Picker("Kennzahl", selection: $metric) {
                ForEach(StatMetric.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if isLoading {
                ProgressView("Lade Daten...")
                    .font(Equans.Fonts.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 12) {
                    Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                    Button("Erneut laden") { load() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                Text("Keine fakturierbaren Buchungen im gewählten Zeitraum.")
                    .font(Equans.Fonts.body)
                    .foregroundColor(Equans.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        StatBarChart(
                            title: "\(metric.rawValue) pro Vertrag",
                            items: items.map { StatChartItem(label: $0.clientname, value: value($0)) },
                            unit: metric.unit
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Equans.Colors.surface)
                    }
                    Section(header: Text("Fakturierung \(period.rawValue) – zum Versenden antippen")) {
                        ForEach(items) { item in
                            Button(action: { selectedItem = item }) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.clientname)
                                            .font(Equans.Fonts.headline)
                                            .foregroundColor(Equans.Colors.textPrimary)
                                        Text(item.contractname)
                                            .font(Equans.Fonts.callout)
                                            .foregroundColor(Equans.Colors.textSecondary)
                                        HStack {
                                            Text("\(item.journalCount) Buchungen · \(item.positionCount) Positionen")
                                                .font(Equans.Fonts.caption)
                                                .foregroundColor(Equans.Colors.textSecondary)
                                            Spacer()
                                            Text(metric.formatted(value(item)))
                                                .font(Equans.Fonts.roboto(15, weight: .bold))
                                                .foregroundColor(Equans.Colors.darkGreen)
                                        }
                                    }
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Equans.Colors.darkGreen)
                                        .padding(.leading, 8)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Gesamt (\(metric.rawValue))")
                                .font(Equans.Fonts.roboto(16, weight: .bold))
                                .foregroundColor(Equans.Colors.textPrimary)
                            Spacer()
                            Text(metric.formatted(grandTotal))
                                .font(Equans.Fonts.roboto(16, weight: .black))
                                .foregroundColor(Equans.Colors.darkGreen)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Equans.Colors.background.ignoresSafeArea())
        .navigationTitle("Fakturierung")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .sheet(item: $selectedItem) { item in
            InvoiceSendSheet(
                item: item,
                contract: contract(for: item),
                periodLabel: period.rawValue,
                lines: invoiceLines(for: item),
                onDismiss: { selectedItem = nil }
            )
        }
    }
    
    private func contract(for item: InvoiceItem) -> Contract? {
        if let id = item.fk_contract, let match = contracts.first(where: { $0.id == id }) {
            return match
        }
        return contracts.first { $0.contractname == item.contractname }
    }
    
    /// Positionszeilen je Buchungsjournal des gewählten Kunden/Vertrags.
    private func invoiceLines(for item: InvoiceItem) -> [InvoiceLine] {
        filteredAggs
            .filter { ($0.clientname ?? "(kein Kunde)") == item.clientname
                && ($0.contractname ?? "(kein Vertrag)") == item.contractname }
            .sorted { $0.created_at < $1.created_at }
            .map { agg in
                let dateStr: String = {
                    guard let d = ReportDateParser.parse(agg.created_at) else { return "" }
                    let f = DateFormatter()
                    f.dateStyle = .short
                    return f.string(from: d)
                }()
                let ref = [agg.bookreference1, agg.bookreference2]
                    .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " / ")
                let title = ref.isEmpty ? "Buchung vom \(dateStr)" : ref
                let detail = "\(dateStr) · \(agg.position_count) Positionen"
                return InvoiceLine(title: title, detail: detail, amount: agg.total_value)
            }
    }
    
    private func load() {
        isLoading = true
        error = nil
        let group = DispatchGroup()
        
        group.enter()
        SupabaseManager.shared.fetchBookJournalAggs { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let aggs):
                    self.aggs = aggs
                case .failure(let err):
                    self.error = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        SupabaseManager.shared.fetchContracts { result in
            DispatchQueue.main.async {
                if case .success(let contracts) = result {
                    self.contracts = contracts
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
}
