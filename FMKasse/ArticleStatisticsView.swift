import SwiftUI

struct ArticleStat: Identifiable {
    let id = UUID()
    let title: String
    let totalQuantity: Double
    let bookingCount: Int
    let totalValue: Double
}

struct ArticleStatisticsView: View {
    @State private var bookDetails: [BookDetail] = []
    @State private var articles: [Article] = []
    @State private var aggs: [BookJournalAgg] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var period: ReportPeriod = .currentMonth
    @State private var metric: StatMetric = .amount
    
    private func value(_ stat: ArticleStat) -> Double {
        switch metric {
        case .amount: return stat.totalValue
        case .bookings: return Double(stat.bookingCount)
        case .positions: return stat.totalQuantity
        }
    }
    
    /// Journal-IDs, die im gewählten Zeitraum liegen.
    private var journalIdsInPeriod: Set<Int64> {
        Set(aggs.compactMap { agg -> Int64? in
            guard let date = ReportDateParser.parse(agg.created_at) else {
                return period == .all ? agg.journal_id : nil
            }
            return period.contains(date) ? agg.journal_id : nil
        })
    }
    
    private var filteredDetails: [BookDetail] {
        let ids = journalIdsInPeriod
        return bookDetails.filter { detail in
            guard let jid = detail.fk_bookjournal else { return false }
            return ids.contains(jid)
        }
    }
    
    private var stats: [ArticleStat] {
        let grouped = Dictionary(grouping: filteredDetails) { $0.fk_article ?? -1 }
        return grouped.map { (articleId, details) in
            let article = articles.first { $0.id == articleId }
            let title = article?.articletitle ?? "Artikel #\(articleId)"
            let rate = article?.articlerate ?? 0
            let quantity = details.reduce(0.0) { $0 + ($1.booknbrsarticle ?? 0) }
            let value = details.reduce(0.0) { $0 + (($1.booknbrsarticle ?? 0) * rate) }
            return ArticleStat(
                title: title,
                totalQuantity: quantity,
                bookingCount: details.count,
                totalValue: value
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
                    Text(m == .positions ? "Menge" : m.rawValue).tag(m)
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
                            title: "\(metric == .positions ? "Menge" : metric.rawValue) pro Artikel",
                            items: stats.map { StatChartItem(label: $0.title, value: value($0)) },
                            unit: metric.unit
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Equans.Colors.surface)
                    }
                    Section(header: Text("Gesamt: \(metric.formatted(grandTotal))")) {
                        ForEach(stats) { stat in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stat.title)
                                    .font(Equans.Fonts.headline)
                                    .foregroundColor(Equans.Colors.textPrimary)
                                HStack {
                                    Text("Menge: \(String(format: "%.2f", stat.totalQuantity)) · \(stat.bookingCount)x gebucht")
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
        .navigationTitle("Artikelstatistik")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }
    
    private func load() {
        isLoading = true
        error = nil
        let group = DispatchGroup()
        
        group.enter()
        SupabaseManager.shared.fetchBookDetails { result in
            DispatchQueue.main.async {
                if case .success(let details) = result {
                    self.bookDetails = details
                } else if case .failure(let err) = result {
                    self.error = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        SupabaseManager.shared.fetchArticles { result in
            DispatchQueue.main.async {
                if case .success(let articles) = result {
                    self.articles = articles
                } else if case .failure(let err) = result {
                    self.error = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        SupabaseManager.shared.fetchBookJournalAggs { result in
            DispatchQueue.main.async {
                if case .success(let aggs) = result {
                    self.aggs = aggs
                } else if case .failure(let err) = result {
                    self.error = err.localizedDescription
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
}
