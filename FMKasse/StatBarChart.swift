import SwiftUI
import Charts

struct StatChartItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

/// Wiederverwendbares horizontales Balkendiagramm für Umsatz-Auswertungen.
/// Zeigt die Top-N Einträge nach Wert.
struct StatBarChart: View {
    let title: String
    let items: [StatChartItem]
    var maxItems: Int = 8
    var unit: String = "CHF"

    private var topItems: [StatChartItem] {
        Array(items.sorted { $0.value > $1.value }.prefix(maxItems))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Equans.Fonts.headline)
                .foregroundColor(Equans.Colors.textPrimary)
                .padding(.horizontal)

            if topItems.isEmpty {
                Text("Keine Daten für die Grafik.")
                    .font(Equans.Fonts.caption)
                    .foregroundColor(Equans.Colors.textSecondary)
                    .padding(.horizontal)
            } else {
                Chart(topItems) { item in
                    BarMark(
                        x: .value("Wert", item.value),
                        y: .value("Name", item.label)
                    )
                    .foregroundStyle(Equans.Colors.darkGreen.gradient)
                    .annotation(position: .trailing) {
                        Text(String(format: "%.0f", item.value))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .frame(height: CGFloat(topItems.count) * 38 + 20)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}
