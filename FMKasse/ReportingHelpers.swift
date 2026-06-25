import Foundation

enum ReportDateParser {
    /// Robustes Parsen von Supabase-Timestamps (mit/ohne Bruchteile, verschiedene Formate).
    static func parse(_ dateString: String) -> Date? {
        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: dateString) { return date }

        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        if let date = isoStandard.date(from: dateString) { return date }

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
            if let date = formatter.date(from: dateString) { return date }
        }
        return nil
    }
}

/// Zeitraum-Filter für Reporting-Auswertungen.
enum ReportPeriod: String, CaseIterable, Identifiable {
    case currentMonth = "Akt. Monat"
    case lastMonth = "Letzter Monat"
    case currentYear = "Akt. Jahr"
    case all = "Gesamt"

    var id: String { rawValue }

    /// Prüft, ob ein Datum im gewählten Zeitraum liegt.
    func contains(_ date: Date, now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .all:
            return true
        case .currentMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
                && calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: lastMonth, toGranularity: .month)
                && calendar.isDate(date, equalTo: lastMonth, toGranularity: .year)
        case .currentYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

func formatCHF(_ value: Double) -> String {
    String(format: "%.2f CHF", value)
}

/// Umschaltbare Kennzahl für Reporting-Auswertungen.
enum StatMetric: String, CaseIterable, Identifiable {
    case amount = "Betrag"
    case bookings = "Buchungen"
    case positions = "Positionen"

    var id: String { rawValue }

    /// Einheit für die Chart-Anzeige.
    var unit: String {
        switch self {
        case .amount: return "CHF"
        case .bookings: return "Buchungen"
        case .positions: return "Positionen"
        }
    }

    /// Formatiert einen Wert passend zur Kennzahl.
    func formatted(_ value: Double) -> String {
        switch self {
        case .amount:
            return formatCHF(value)
        case .bookings, .positions:
            return String(format: "%.0f", value)
        }
    }
}
