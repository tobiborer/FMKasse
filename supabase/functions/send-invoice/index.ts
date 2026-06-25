// @ts-nocheck — Datei läuft in der Deno-Runtime von Supabase.
// Supabase Edge Function: send-invoice
// Versendet Dateien (PDF, CSV, XLSX) per E-Mail über SMTP (innosol.swiss).
//
// Erwartet JSON-Body:
//   { to, subject, body, fileName, pdfBase64 }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const SMTP_HOST = Deno.env.get("SMTP_HOST") ?? "";
const SMTP_PORT = parseInt(Deno.env.get("SMTP_PORT") ?? "465");
const SMTP_USER = Deno.env.get("SMTP_USER") ?? "";
const SMTP_PASS = Deno.env.get("SMTP_PASS") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface SendPayload {
  to: string;
  subject: string;
  body: string;
  fileName: string;
  pdfBase64: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
      throw new Error("SMTP-Konfiguration unvollständig (SMTP_HOST, SMTP_USER oder SMTP_PASS fehlt).");
    }

    const payload = (await req.json()) as SendPayload;

    if (!payload.to || !payload.pdfBase64) {
      throw new Error("Pflichtfelder fehlen (to, pdfBase64).");
    }

    const client = new SMTPClient({
      connection: {
        hostname: SMTP_HOST,
        port: SMTP_PORT,
        tls: true,
        auth: { username: SMTP_USER, password: SMTP_PASS },
      },
    });

    await client.send({
      from: SMTP_USER,
      to: payload.to,
      subject: payload.subject,
      content: payload.body,
      attachments: [
        {
          filename: payload.fileName,
          content: payload.pdfBase64,
          encoding: "base64",
        },
      ],
    });

    await client.close();

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ success: false, error: message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  }
});
