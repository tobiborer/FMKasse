# FMKasse – EQUANS Design System

Die App nutzt das offizielle EQUANS Graphic Design (Stand Januar 2025), Stilrichtung
**"Hell & clean"** (helle Flächen, EQUANS-Grün als Akzent).

Zentrale Datei: `EquansTheme.swift`

## Farben (offizielle Marken-Hex-Werte)

| Token | Hex | Verwendung |
| --- | --- | --- |
| Dark Blue (Primär) | `#002439` | Text, Buttons, Logo |
| Turquoise Green (Akzent) | `#70BD95` | Diagramme, Highlights |
| Dark Green (digital) | `#008163` | Beträge, Erfolg |
| White | `#FFFFFF` | Flächen/Karten |
| Background | `#F5F7F9` | App-Hintergrund |
| Text Secondary | `#5A6B76` | Untertitel |
| Border | `#E2E8ED` | Karten-Rahmen |
| Danger | `#E2342E` | Fehler/Löschen |

Sekundärfarben (Azure, Violet, Orange, Pink, Yellow, Apple/Lime Green, Light Blue)
sind ebenfalls in `Equans.Colors` definiert – laut Richtlinie max. **eine** pro Screen.

## Typografie – Roboto

Die Richtlinie schreibt **Roboto** vor. `EquansTheme.swift` nutzt automatisch Roboto,
wenn die Schrift im Projekt eingebunden ist – sonst System-Font (San Francisco) als Fallback.
Damit läuft die App auch ohne die Font-Dateien, sieht aber mit Roboto markenkonform aus.

### Roboto einbinden (einmalig in Xcode)

1. **Download:** https://fonts.google.com/specimen/Roboto → "Get font" → "Download all"
2. Aus dem ZIP folgende statischen TTFs verwenden (Ordner `static/` bei neueren Paketen):
   - `Roboto-Light.ttf`
   - `Roboto-Regular.ttf`
   - `Roboto-Medium.ttf`
   - `Roboto-Bold.ttf`
   - `Roboto-Black.ttf`
3. **In Xcode** die 5 Dateien in das Projekt ziehen (Target **FMKasse** anhaken,
   "Copy items if needed" aktiv).
4. **Info.plist** → Schlüssel **"Fonts provided by application"** (`UIAppFonts`) ergänzen:

```xml
<key>UIAppFonts</key>
<array>
    <string>Roboto-Light.ttf</string>
    <string>Roboto-Regular.ttf</string>
    <string>Roboto-Medium.ttf</string>
    <string>Roboto-Bold.ttf</string>
    <string>Roboto-Black.ttf</string>
</array>
```

5. **Build & Run.** Die App verwendet ab jetzt Roboto. Prüfen lässt sich das per:

```swift
for family in UIFont.familyNames where family.contains("Roboto") {
    print(family, UIFont.fontNames(forFamilyName: family))
}
```

> Wichtig: Die PostScript-Namen müssen `Roboto-Light/Regular/Medium/Bold/Black` lauten
> (so erwartet sie `Equans.Fonts.roboto(...)`). Bei abweichenden Namen die Strings in
> `EquansTheme.swift` anpassen.

## Wiederverwendbare Bausteine

| Element | Verwendung |
| --- | --- |
| `Equans.Colors.*` | Alle Farben |
| `Equans.Fonts.roboto(size, weight:)` | Schrift mit Fallback |
| `Equans.Fonts.title/headline/body/...` | Vordefinierte Textstile |
| `EquansPrimaryButtonStyle()` | Dunkelblauer Hauptbutton |
| `EquansSecondaryButtonStyle()` | Türkis-Umriss-Button |
| `EquansCard { ... }` | Karten-Container |
| `.equansBackground()` | Standard-Screen-Hintergrund |

## Umgestellte Screens

- Login, Hauptmenü (Kacheln), Geräte-Info-Box
- Reporting-Menü + Kunden-/Artikel-/Geräte-Statistik + Balkendiagramme
- Fakturierung + Versand-Sheet
- Verträge & Artikel (Liste, Detail, Artikelgruppe, Artikel)
- Einstellungen (Code-Gate + Formular)
- Kassenterminal (Buchungsliste, Vertragsauswahl, Buchung bearbeiten)
