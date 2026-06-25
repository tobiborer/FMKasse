import SwiftUI

struct ReportingMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showExport = false

    var body: some View {
        NavigationStack {
            ZStack {
                Equans.Colors.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer().frame(height: 8)
                    Text("Reporting")
                        .font(Equans.Fonts.largeTitle)
                        .foregroundColor(Equans.Colors.textPrimary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 18) {
                        NavigationLink(destination: CustomerStatisticsView()) {
                            MenuTile(title: "Kundenstatistik", systemImage: "person.2.fill", accent: Equans.Colors.darkBlue)
                        }
                        NavigationLink(destination: ArticleStatisticsView()) {
                            MenuTile(title: "Artikelstatistik", systemImage: "shippingbox.fill", accent: Equans.Colors.darkGreen)
                        }
                        NavigationLink(destination: DeviceStatisticsView()) {
                            MenuTile(title: "Gerätestatistik", systemImage: "desktopcomputer", accent: Equans.Colors.darkGreen)
                        }
                        NavigationLink(destination: InvoicingView()) {
                            MenuTile(title: "Fakturierung", systemImage: "doc.text.fill", accent: Equans.Colors.darkBlue)
                        }
                        NavigationLink(destination: BookingTimeStatisticsView()) {
                            MenuTile(title: "Buchungszeiten", systemImage: "clock.fill", accent: Equans.Colors.darkBlue)
                        }
                        Button(action: { showExport = true }) {
                            MenuTile(title: "Datenexport", systemImage: "square.and.arrow.up.fill", accent: Equans.Colors.darkGreen)
                        }
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                }
            }
            .sheet(isPresented: $showExport) { DataExportView() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(Equans.Colors.darkBlue)
                }
            }
        }
    }
}
