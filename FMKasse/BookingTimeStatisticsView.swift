import SwiftUI
import Charts

struct HourBucket: Identifiable {
    let id = UUID()
    let hour: Int          // 0...23
    let count: Int
    var label: String { String(format: "%02d:00", hour) }
}

struct BookingTimeStatisticsView: View {
    @State private var aggs: [BookJournalAgg] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var period: ReportPeriod = .currentMonth
    @State private var selectedContract: String = allContracts

    private static let allContracts = "Alle Verträge"

    // Auf Zeitraum gefilterte Buchungen
    private var filteredAggs: [BookJournalAgg] {
        aggs.filter { agg in
            guard let date = ReportDateParser.parse(agg.created_at) else { return period == .all }
            return period.contains(date)
        }
    }

    // Liste der Verträge für den Picker
    private var contractNames: [String] {
        let names = Set(filteredAggs.map { $0.contractname ?? "(kein Vertrag)" })
        return [Self.allContracts] + names.sorted()
    }

    // Buchungen des gewählten Vertrags
    private var contractAggs: [BookJournalAgg] {
        guard selectedContract != Self.allContracts else { return filteredAggs }
        return filteredAggs.filter { ($0.contractname ?? "(kein Vertrag)") == selectedContract }
    }

    // Verteilung über 24 Stunden
    private var hourBuckets: [HourBucket] {
        var counts = Array(repeating: 0, count: 24)
        let calendar = Calendar.current
        for agg in contractAggs {
            if let date = ReportDateParser.parse(agg.created_at) {
                let hour = calendar.component(.hour, from: date)
                if hour >= 0 && hour < 24 { counts[hour] += 1 }
            }
        }
        return (0..<24).map { HourBucket(hour: $0, count: counts[$0]) }
    }

    private var totalBookings: Int {
        hourBuckets.reduce(0) { $0 + $1.count }
    }

    private var peakHour: HourBucket? {
        hourBuckets.filter { $0.count > 0 }.max { $0.count < $1.count }
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

            // Vertragsauswahl
            HStack {
                Text("Vertrag")
                    .font(Equans.Fonts.callout)
                    .foregroundColor(Equans.Colors.textSecondary)
                Spacer()
                Picker("Vertrag", selection: $selectedContract) {
                    ForEach(contractNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                .tint(Equans.Colors.darkBlue)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

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
            } else if totalBookings == 0 {
                Text("Keine Buchungen im gewählten Zeitraum.")
                    .font(Equans.Fonts.body)
                    .foregroundColor(Equans.Colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Kennzahlen
                        HStack(spacing: 12) {
                            statCard(title: "Buchungen", value: "\(totalBookings)")
                            statCard(title: "Stoßzeit", value: peakHour.map { String(format: "%02d:00", $0.hour) } ?? "-")
                        }
                        .padding(.horizontal)

                        // Diagramm: Buchungen pro Stunde
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Buchungen nach Uhrzeit")
                                .font(Equans.Fonts.headline)
                                .foregroundColor(Equans.Colors.textPrimary)
                                .padding(.horizontal)

                            Chart(hourBuckets) { bucket in
                                BarMark(
                                    x: .value("Stunde", bucket.hour),
                                    y: .value("Buchungen", bucket.count)
                                )
                                .foregroundStyle(Equans.Colors.darkGreen.gradient)
                            }
                            .chartXScale(domain: 0...23)
                            .chartXAxis {
                                AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21]) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let hour = value.as(Int.self) {
                                            Text(String(format: "%02d", hour))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 260)
                            .padding(.horizontal)
                        }

                        Text("Verteilung der erfassten Buchungen über die Tageszeit (0–23 Uhr).")
                            .font(Equans.Fonts.caption)
                            .foregroundColor(Equans.Colors.textSecondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(Equans.Colors.background.ignoresSafeArea())
        .navigationTitle("Buchungszeiten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    @ViewBuilder
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Equans.Fonts.caption)
                .foregroundColor(Equans.Colors.textSecondary)
            Text(value)
                .font(Equans.Fonts.roboto(22, weight: .black))
                .foregroundColor(Equans.Colors.darkBlue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Equans.Colors.surface)
        .cornerRadius(Equans.Layout.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                .stroke(Equans.Colors.border, lineWidth: 1)
        )
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
