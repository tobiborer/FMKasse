import Foundation

/// Zentrale Konfiguration für SSO / OAuth (Azure AD / Microsoft Entra ID).
///
/// SETUP-CHECKLISTE (nach IT-Freigabe ausfüllen):
///
/// TEIL A — Azure-Portal (Entra ID → App registrations):
///   1. Neue App-Registrierung anlegen (z.B. "FMKasse iOS").
///   2. Unter "Authentication" → "Add a platform" → "Web" die folgende
///      Redirect-URI eintragen (Supabase-Callback):
///         https://fpuhsrwfhaekvviuqpcx.supabase.co/auth/v1/callback
///   3. Unter "Certificates & secrets" ein Client-Secret erzeugen.
///   4. Client-ID (Application ID), Secret und Directory (Tenant) ID notieren.
///   5. API permissions: openid, email, profile (delegated).
///
/// TEIL B — Supabase-Dashboard (Authentication → Providers → Azure):
///   1. Azure aktivieren.
///   2. Client-ID + Secret eintragen.
///   3. Azure Tenant URL eintragen, z.B.:
///         https://login.microsoftonline.com/<TENANT_ID>
///   4. Unter Authentication → URL Configuration die App-Redirect-URL
///      (redirectScheme unten) als "Additional Redirect URL" hinzufügen:
///         fmkasse://login-callback
///
/// TEIL C — Xcode (Info.plist):
///   URL-Scheme "fmkasse" registrieren (siehe Anleitung unten in dieser Datei).
///
enum AuthConfig {
    /// Custom URL-Scheme der App für den OAuth-Rücksprung (Deep Link).
    /// Muss in Info.plist als URL Type eingetragen sein.
    static let redirectScheme = "fmkasse"

    /// Vollständige Redirect-URL, die nach erfolgreichem Login aufgerufen wird.
    /// Diese URL muss in Supabase unter "Additional Redirect URLs" hinterlegt sein.
    static let redirectURL = URL(string: "\(redirectScheme)://login-callback")!

    /// Schaltet den Azure-SSO-Button im Login ein/aus.
    /// Erst auf `true` setzen, wenn Teil A + B abgeschlossen sind.
    static let azureSSOEnabled = true
}
