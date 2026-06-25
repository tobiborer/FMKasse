import Foundation

enum AppInfo {
    /// Versionsstring im Format "V TT.MM.JJJJ" basierend auf dem Build-Datum.
    static var versionString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return "V \(formatter.string(from: buildDate))"
    }

    /// Build-Datum = Änderungsdatum der ausführbaren Datei.
    static var buildDate: Date {
        if let execURL = Bundle.main.executableURL,
           let attrs = try? FileManager.default.attributesOfItem(atPath: execURL.path),
           let modDate = attrs[.modificationDate] as? Date {
            return modDate
        }
        return Date()
    }
}
