// @ts-nocheck
// Supabase Edge Function: create-user
// Legt einen neuen Auth-User an (oder aktualisiert Profil) und sendet
// die Einladungs-E-Mail über SMTP (innosol.swiss).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SMTP_HOST = Deno.env.get("SMTP_HOST") ?? "";
const SMTP_PORT = parseInt(Deno.env.get("SMTP_PORT") ?? "465");
const SMTP_USER = Deno.env.get("SMTP_USER") ?? "";
const SMTP_PASS = Deno.env.get("SMTP_PASS") ?? "";

async function sendMail(to: string, subject: string, html: string): Promise<void> {
  const client = new SMTPClient({
    connection: {
      hostname: SMTP_HOST,
      port: SMTP_PORT,
      tls: true,
      auth: { username: SMTP_USER, password: SMTP_PASS },
    },
  });
  await client.send({ from: SMTP_USER, to, subject, html });
  await client.close();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, displayname, role } = await req.json();

    if (!email) {
      return new Response(JSON.stringify({ error: "E-Mail fehlt" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    let userId: string | null = null;
    let inviteLink: string | null = null;

    // 1. Prüfen ob User bereits existiert
    const { data: listData } = await supabaseAdmin.auth.admin.listUsers();
    const existing = listData?.users?.find((u: any) => u.email === email);

    if (existing) {
      userId = existing.id;
      const { data: linkData } = await supabaseAdmin.auth.admin.generateLink({
        type: "recovery",
        email,
        options: { redirectTo: "fmkasse://login-callback" },
      });
      inviteLink = linkData?.properties?.action_link ?? null;
    } else {
      const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email,
        email_confirm: false,
      });
      if (authError) {
        return new Response(JSON.stringify({ error: authError.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      userId = authData.user?.id ?? null;
      const { data: linkData } = await supabaseAdmin.auth.admin.generateLink({
        type: "invite",
        email,
        options: { redirectTo: "fmkasse://login-callback" },
      });
      inviteLink = linkData?.properties?.action_link ?? null;
    }

    if (!userId) {
      return new Response(JSON.stringify({ error: "User-ID nicht erhalten" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Profil anlegen oder aktualisieren
    const { error: profileError } = await supabaseAdmin
      .from("userprofile")
      .upsert({ id: userId, email, displayname: displayname ?? null, role: role ?? "USER" }, { onConflict: "id" });

    if (profileError) {
      return new Response(JSON.stringify({ error: profileError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Einladungs-E-Mail über SMTP versenden
    let emailSent = false;
    if (inviteLink && SMTP_HOST && SMTP_USER && SMTP_PASS) {
      const name = displayname ?? email;
      const isNew = !existing;
      const subject = isNew ? "Einladung zur FM Kasse" : "Zugang zur FM Kasse";
      const html = isNew
        ? `<p>Hallo ${name},</p>
           <p>Sie wurden zur <strong>FM Kasse</strong> eingeladen.</p>
           <p>Klicken Sie auf den folgenden Link, um Ihr Passwort zu setzen und sich anzumelden:</p>
           <p><a href="${inviteLink}" style="background:#008163;color:white;padding:12px 24px;border-radius:6px;text-decoration:none;display:inline-block;">Konto aktivieren</a></p>
           <p>Der Link ist 24 Stunden gültig.</p>
           <p>FM Kasse Team</p>`
        : `<p>Hallo ${name},</p>
           <p>Ihr Konto in der <strong>FM Kasse</strong> wurde aktualisiert (Berechtigung: ${role ?? "USER"}).</p>
           <p>Falls Sie Ihr Passwort vergessen haben, können Sie es über diesen Link zurücksetzen:</p>
           <p><a href="${inviteLink}" style="background:#008163;color:white;padding:12px 24px;border-radius:6px;text-decoration:none;display:inline-block;">Passwort zurücksetzen</a></p>
           <p>FM Kasse Team</p>`;

      try {
        await sendMail(email, subject, html);
        emailSent = true;
      } catch (mailError) {
        // User wurde angelegt, aber Mail fehlgeschlagen – im Response vermerken
        return new Response(
          JSON.stringify({ success: true, userId, emailSent: false, emailError: String(mailError) }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    return new Response(JSON.stringify({ success: true, userId, emailSent }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
