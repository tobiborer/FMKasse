import UIKit

/// Eine einzelne Position auf der Rechnungsbeilage.
struct InvoiceLine {
    let title: String
    let detail: String
    let amount: Double
}

/// Eingabedaten für die Erzeugung der Rechnungsbeilage.
struct InvoicePDFInput {
    let clientName: String
    let contractName: String
    let billingAddress: [String]   // Adresszeilen (bereits aufbereitet)
    let clientNo: String?
    let costCenter: String?
    let periodLabel: String        // z.B. "Akt. Monat" oder Datumsbereich
    let lines: [InvoiceLine]
    let total: Double
    let totalPositions: Int
    let totalBookings: Int
}

enum InvoicePDFGenerator {
    private static let pageWidth: CGFloat = 595.2   // A4 @ 72dpi
    private static let pageHeight: CGFloat = 841.8
    private static let margin: CGFloat = 48

    private static let equansGreen = UIColor(red: 0.0, green: 0.4, blue: 0.2, alpha: 1.0)

    /// Erzeugt das PDF und liefert die Roh-Daten zurück.
    static func generate(_ input: InvoicePDFInput) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y = margin

            y = drawHeader(at: y)
            y = drawClientBlock(input, at: y)
            y = drawTitle(input, at: y)
            y = drawTable(input, at: y, context: ctx)
            drawFooter()
        }
    }

    // MARK: - Header (Logo)

    private static func drawHeader(at y: CGFloat) -> CGFloat {
        var newY = y
        if let logo = UIImage(named: "Equans_Black") {
            let maxWidth: CGFloat = 160
            let ratio = logo.size.height / max(logo.size.width, 1)
            let w = min(maxWidth, logo.size.width)
            let h = w * ratio
            let rect = CGRect(x: margin, y: newY, width: w, height: h)
            logo.draw(in: rect)
            newY += h + 8
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: equansGreen
            ]
            "EQUANS".draw(at: CGPoint(x: margin, y: newY), withAttributes: attrs)
            newY += 40
        }

        // Trennlinie
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: newY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: newY))
        equansGreen.setStroke()
        path.lineWidth = 1.5
        path.stroke()
        return newY + 24
    }

    // MARK: - Kunden- / Rechnungsadresse

    private static func drawClientBlock(_ input: InvoicePDFInput, at y: CGFloat) -> CGFloat {
        var newY = y
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        "RECHNUNGSADRESSE".draw(at: CGPoint(x: margin, y: newY), withAttributes: labelAttrs)
        newY += 16

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.black
        ]
        input.clientName.draw(at: CGPoint(x: margin, y: newY), withAttributes: nameAttrs)
        newY += 18

        let lineAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        for line in input.billingAddress where !line.isEmpty {
            line.draw(at: CGPoint(x: margin, y: newY), withAttributes: lineAttrs)
            newY += 15
        }

        if let no = input.clientNo, !no.isEmpty {
            "Kundennr.: \(no)".draw(at: CGPoint(x: margin, y: newY), withAttributes: lineAttrs)
            newY += 15
        }
        return newY + 16
    }

    // MARK: - Titel + Meta

    private static func drawTitle(_ input: InvoicePDFInput, at y: CGFloat) -> CGFloat {
        var newY = y
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: equansGreen
        ]
        "Rechnungsbeilage".draw(at: CGPoint(x: margin, y: newY), withAttributes: titleAttrs)
        newY += 26

        let metaAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())

        "Vertrag: \(input.contractName)".draw(at: CGPoint(x: margin, y: newY), withAttributes: metaAttrs)
        newY += 15
        "Periode: \(input.periodLabel)".draw(at: CGPoint(x: margin, y: newY), withAttributes: metaAttrs)
        newY += 15
        "Erstellt am: \(dateString)".draw(at: CGPoint(x: margin, y: newY), withAttributes: metaAttrs)
        newY += 15
        if let cc = input.costCenter, !cc.isEmpty {
            "Kostenstelle: \(cc)".draw(at: CGPoint(x: margin, y: newY), withAttributes: metaAttrs)
            newY += 15
        }
        return newY + 16
    }

    // MARK: - Positionstabelle

    private static func drawTable(_ input: InvoicePDFInput, at y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var newY = y
        let colAmountX = pageWidth - margin - 90

        // Kopfzeile
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.white
        ]
        let headerRect = CGRect(x: margin, y: newY, width: pageWidth - 2 * margin, height: 22)
        equansGreen.setFill()
        UIBezierPath(rect: headerRect).fill()
        "Position".draw(at: CGPoint(x: margin + 8, y: newY + 5), withAttributes: headerAttrs)
        "Betrag (CHF)".draw(at: CGPoint(x: colAmountX, y: newY + 5), withAttributes: headerAttrs)
        newY += 22

        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ]
        let amountAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        var index = 0
        for line in input.lines {
            // Seitenumbruch bei Bedarf
            if newY > pageHeight - margin - 120 {
                context.beginPage()
                newY = margin
            }
            if index % 2 == 1 {
                UIColor(white: 0.96, alpha: 1.0).setFill()
                UIBezierPath(rect: CGRect(x: margin, y: newY, width: pageWidth - 2 * margin, height: 30)).fill()
            }
            line.title.draw(at: CGPoint(x: margin + 8, y: newY + 5), withAttributes: rowAttrs)
            if !line.detail.isEmpty {
                line.detail.draw(at: CGPoint(x: margin + 8, y: newY + 18), withAttributes: detailAttrs)
            }
            let amountStr = String(format: "%.2f", line.amount)
            amountStr.draw(at: CGPoint(x: colAmountX, y: newY + 5), withAttributes: amountAttrs)
            newY += 30
            index += 1
        }

        // Summenzeile
        newY += 6
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: newY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: newY))
        UIColor.darkGray.setStroke()
        path.lineWidth = 1
        path.stroke()
        newY += 10

        let totalLabelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.black
        ]
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: equansGreen
        ]
        "Gesamtbetrag".draw(at: CGPoint(x: margin + 8, y: newY), withAttributes: totalLabelAttrs)
        String(format: "%.2f CHF", input.total).draw(at: CGPoint(x: colAmountX, y: newY), withAttributes: totalAttrs)
        newY += 24

        let summaryAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        "\(input.totalBookings) Buchungen · \(input.totalPositions) Positionen"
            .draw(at: CGPoint(x: margin + 8, y: newY), withAttributes: summaryAttrs)
        return newY + 20
    }

    // MARK: - Footer

    private static func drawFooter() {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.lightGray
        ]
        let text = "Diese Rechnungsbeilage wurde automatisch durch die FM Kasse erstellt."
        let size = (text as NSString).size(withAttributes: footerAttrs)
        text.draw(at: CGPoint(x: (pageWidth - size.width) / 2, y: pageHeight - margin), withAttributes: footerAttrs)
    }
}
