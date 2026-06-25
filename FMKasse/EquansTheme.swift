import SwiftUI

// MARK: - Color (Hex)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - EQUANS Design System

enum Equans {

    // MARK: Brand Colours (official Graphic Design Guidelines, Jan 2025)
    enum Colors {
        static let darkBlue = Color(hex: "002439")   // PRIMARY
        static let turquoise = Color(hex: "70BD95")  // main accent
        static let darkGreen = Color(hex: "008163")  // digital accent
        static let white = Color(hex: "FFFFFF")

        // Accompanying palette (use sparingly, max one accent per screen)
        static let azureBlue = Color(hex: "0059CE")
        static let violet = Color(hex: "C865FF")
        static let orange = Color(hex: "FF9600")
        static let pink = Color(hex: "FF0080")
        static let yellow = Color(hex: "FFCA00")
        static let appleGreen = Color(hex: "76C512")
        static let limeGreen = Color(hex: "B7F100")
        static let lightBlue = Color(hex: "00DEE8")

        // Semantic UI tokens
        static let background = Color(hex: "F5F7F9")   // soft light background
        static let surface = Color.white
        static let textPrimary = darkBlue
        static let textSecondary = Color(hex: "5A6B76")
        static let border = Color(hex: "E2E8ED")
        static let accent = darkGreen
        static let success = darkGreen
        static let danger = Color(hex: "E2342E")
    }

    // MARK: Typography (Roboto with graceful system fallback)
    enum Fonts {
        /// Liefert Roboto in der gewünschten Größe/Stärke; fällt auf System-Font zurück,
        /// falls Roboto nicht im Projekt eingebunden ist.
        static func roboto(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            let name: String
            switch weight {
            case .black, .heavy: name = "Roboto-Black"
            case .bold, .semibold: name = "Roboto-Bold"
            case .medium: name = "Roboto-Medium"
            case .light, .thin, .ultraLight: name = "Roboto-Light"
            default: name = "Roboto-Regular"
            }
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
            return .system(size: size, weight: weight)
        }

        static let largeTitle = roboto(30, weight: .black)
        static let title = roboto(22, weight: .bold)
        static let headline = roboto(17, weight: .bold)
        static let body = roboto(15, weight: .regular)
        static let callout = roboto(14, weight: .medium)
        static let caption = roboto(12, weight: .regular)
        static let tileTitle = roboto(15, weight: .medium)
    }

    // MARK: Layout tokens
    enum Layout {
        static let cornerRadius: CGFloat = 18
        static let cardRadius: CGFloat = 16
        static let spacing: CGFloat = 16
        static let cardShadow = Color.black.opacity(0.06)
    }
}

// MARK: - Reusable View Styles

/// Primärer EQUANS-Button (dunkelblau, weiße Schrift).
struct EquansPrimaryButtonStyle: ButtonStyle {
    var color: Color = Equans.Colors.darkBlue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Equans.Fonts.roboto(16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(Equans.Layout.cornerRadius)
    }
}

/// Sekundärer Button (Umriss in EQUANS-Türkis).
struct EquansSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Equans.Fonts.roboto(16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Equans.Colors.turquoise.opacity(configuration.isPressed ? 0.15 : 0.0))
            .foregroundColor(Equans.Colors.darkBlue)
            .overlay(
                RoundedRectangle(cornerRadius: Equans.Layout.cornerRadius)
                    .stroke(Equans.Colors.turquoise, lineWidth: 1.5)
            )
            .cornerRadius(Equans.Layout.cornerRadius)
    }
}

/// Karten-Container im EQUANS-Stil.
struct EquansCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(Equans.Layout.spacing)
            .background(Equans.Colors.surface)
            .cornerRadius(Equans.Layout.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                    .stroke(Equans.Colors.border, lineWidth: 1)
            )
            .shadow(color: Equans.Layout.cardShadow, radius: 8, x: 0, y: 3)
    }
}

extension View {
    /// Standard-Hintergrund für EQUANS-Screens.
    func equansBackground() -> some View {
        self.background(Equans.Colors.background.ignoresSafeArea())
    }
}
