# FMKasse – Azure AD / Microsoft Entra ID SSO Setup

Der App-Code ist vollständig vorbereitet. Es fehlen nur noch die Konfigurationsschritte
in Azure, Supabase und Xcode (Werte/Einstellungen, kein Code mehr).

## Übersicht

| Wert | Eintragen |
| --- | --- |
| Supabase Callback URL | `https://fpuhsrwfhaekvviuqpcx.supabase.co/auth/v1/callback` |
| App Redirect (Deep Link) | `fmkasse://login-callback` |
| URL-Scheme | `fmkasse` |

---

## TEIL A — Azure-Portal (durch IT)

1. **Entra ID → App registrations → New registration**
   - Name: `FMKasse iOS`
   - Supported account types: je nach Vorgabe (z.B. "Single tenant" für nur EQUANS)
2. **Authentication → Add a platform → Web**
   - Redirect URI: `https://fpuhsrwfhaekvviuqpcx.supabase.co/auth/v1/callback`
3. **Certificates & secrets → New client secret**
   - Wert (Secret) sofort kopieren (wird nur einmal angezeigt)
4. **Notieren:**
   - Application (client) ID
   - Client Secret
   - Directory (tenant) ID
5. **API permissions:** `openid`, `email`, `profile` (Microsoft Graph, delegated)

---

## TEIL B — Supabase-Dashboard

1. **Authentication → Providers → Azure → Enable**
   - Client ID: *(aus Teil A)*
   - Secret: *(aus Teil A)*
   - Azure Tenant URL: `https://login.microsoftonline.com/<TENANT_ID>`
2. **Authentication → URL Configuration → Additional Redirect URLs**
   - Hinzufügen: `fmkasse://login-callback`

---

## TEIL C — Xcode (Info.plist URL-Scheme)

Damit der Rücksprung in die App funktioniert, muss das URL-Scheme `fmkasse`
registriert werden:

1. Projekt → Target **FMKasse** → Tab **Info**
2. Abschnitt **URL Types** → **+**
   - Identifier: `com.equans.fmkasse` (oder Bundle-ID)
   - URL Schemes: `fmkasse`
   - Role: `Editor`

Alternativ direkt in `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.equans.fmkasse</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fmkasse</string>
        </array>
    </dict>
</array>
```

---

## Aktivieren / Deaktivieren

In `AuthConfig.swift`:

```swift
static let azureSSOEnabled = true   // false blendet den SSO-Button aus
```

Falls ein anderes Redirect-Scheme gewünscht ist, dort `redirectScheme` anpassen
(muss mit Info.plist und Supabase übereinstimmen).

---

## Test

1. Teil A + B + C abschließen
2. App starten → Login-Screen → **"Mit EQUANS-Konto anmelden"**
3. Microsoft-Login erscheint → nach Anmeldung Rücksprung in die App
4. Bei Erfolg landet man im Hauptmenü
