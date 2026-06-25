import SwiftUI

struct CustomerStat: Identifiable {
    let id = UUID()
    let clientname: String
    let journalCount: Int
    let positionCount: Int
    let totalValue: Double
}

struct CustomerStatisticsView: View {
    @State private var aggs: [BookJournalAgg] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var period: ReportPeriod = .currentMonth
    @State private var metric: StatMetric = .amount
    
    private func value(_ stat: CustomerStat) -> Double {
        switch metric {
        case .amount: return stat.totalValue
        case .bookings: return Double(stat.journalCount)
        case .positions: return Double(stat.positionCount)
        }
    }
    
    private var filteredAggs: [BookJournalAgg] {
        aggs.filter { agg in
            guard let date = ReportDateParser.parse(agg.created_at) else { return period == .all }
            return period.contains(date)
        }
    }
    
    private var stats: [CustomerStat] {
        let grouped = Dictionary(grouping: filteredAggs) { $0.clientname ?? "(kein Kunde)" }
        return grouped.map { (name, items) in
            CustomerStat(
                clientname: name,
                journalCount: items.count,
                positionCount: items.reduce(0) { $0 + $1.position_count },
                totalValue: items.reduce(0) { $0 + $1.total_value }
            )
        }
        .sorted { value($0) > value($1) }
    }
    
    private var grandTotal: Double {
        stats.reduce(0) { $0 + value($1) }
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
            } else if stats.isEmpty {
                Text("Keine Daten im gewählten Zeitraum.")
                    .font(Equans.Fonts.body)
                    .foregroundColor(Equans.Colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        StatBarChart(
                            title: "\(metric.rawValue) pro Kunde",
                            items: stats.map { StatChartItem(label: $0.clientname, value: value($0)) },
                            unit: metric.unit
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Equans.Colors.surface)
                    }
                    Section(header: Text("Gesamt: \(metric.formatted(grandTotal))")) {
                        ForEach(stats) { stat in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stat.clientname)
                                    .font(Equans.Fonts.headline)
                                    .foregroundColor(Equans.Colors.textPrimary)
                                HStack {
                                    Text("\(stat.journalCount) Buchungen · \(stat.positionCount) Positionen")
                                        .font(Equans.Fonts.caption)
                                        .foregroundColor(Equans.Colors.textSecondary)
                                    Spacer()
                                    Text(metric.formatted(value(stat)))
                                        .font(Equans.Fonts.roboto(15, weight: .bold))
                                        .foregroundColor(Equans.Colors.darkGreen)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Equans.Colors.background.ignoresSafeArea())
        .navigationTitle("Kundenstatistik")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }
    
    private func load() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchBookJournalAggs { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let aggs):
                    self.aggs = aggs
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }
}
