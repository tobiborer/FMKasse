# FMKasse – Rechnungsbeilage per E-Mail (Backend-Versand)

Die App erzeugt die Rechnungsbeilage als PDF (EQUANS-Logo, Rechnungsadresse,
Periode, Positionen, Summe) und schickt sie base64-kodiert an die Supabase
Edge Function `send-invoice`, die den Versand vollautomatisch über **Resend**
durchführt – unabhängig davon, ob das Tablet ein Mailkonto hat.

## Architektur

```
App (InvoiceSendSheet)
  → PDF erzeugen (InvoicePDFGenerator)
  → SupabaseManager.sendInvoiceEmail(...)
      → Edge Function "send-invoice"
          → Resend API  → E-Mail mit PDF-Anhang an Zieladresse
```

---

## 1. Resend-Konto einrichten (einmalig)

1. Konto erstellen unter https://resend.com
2. **Domain verifizieren** (z.B. `equans.ch`) unter Domains → Add Domain
   - DNS-Einträge (SPF/DKIM) durch eure IT setzen lassen
   - Ohne eigene Domain kann zum Testen `onboarding@resend.dev` als Absender dienen
3. **API Key** erzeugen (API Keys → Create) und kopieren

---

## 2. Edge Function deployen

Voraussetzung: Supabase CLI installiert (`brew install supabase/tap/supabase`).

```bash
# im Projektordner (dort wo der Ordner "supabase" liegt)
supabase login
supabase link --project-ref fpuhsrwfhaekvviuqpcx

# Secrets setzen
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxx
supabase secrets set INVOICE_FROM="EQUANS FM Kasse <fmkasse@equans.ch>"

# Function deployen
supabase functions deploy send-invoice
```

> Hinweis: Die TypeScript-Lint-Fehler zu `Deno` / `https://deno.land/...` in
> `index.ts` erscheinen nur in Xcode/Node-Tooling. In der Deno-Laufzeit von
> Supabase ist der Code korrekt und lauffähig.

---

## 3. Zugriff / Authentifizierung

Die App ruft die Function mit dem Supabase-anon-Key auf (bereits konfiguriert).
Standardmässig verlangt eine Edge Function ein gültiges JWT. Da Nutzer in der
App eingeloggt sind, wird das Session-Token automatisch mitgesendet.

Falls die Function ohne Login erreichbar sein soll, beim Deploy ergänzen:

```bash
supabase functions deploy send-invoice --no-verify-jwt
```

---

## 4. Nutzung in der App

1. Reporting → **Fakturierung**
2. Zeitraum/Kennzahl wählen
3. Auf einen **Kunden tippen** (Briefsymbol)
4. Zieladresse eingeben (die zuletzt benutzte ist vorausgefüllt)
5. **"Rechnungsbeilage per Mail versenden"** → PDF wird erzeugt und versendet

---

## Anpassungen

| Was | Wo |
| --- | --- |
| Absenderadresse | Secret `INVOICE_FROM` |
| PDF-Layout / Logo / Texte | `InvoicePDFGenerator.swift` |
| Mailtext / Betreff | `InvoiceSendSheet.swift` (Funktion `send()`) |
| Positionszeilen-Aufbau | `InvoicingView.swift` (`invoiceLines(for:)`) |

---

## Test ohne Domain

Zum schnellen Test ohne verifizierte Domain:
- `INVOICE_FROM` = `onboarding@resend.dev`
- Empfänger muss die im Resend-Konto hinterlegte E-Mail sein (Test-Modus-Beschränkung)
