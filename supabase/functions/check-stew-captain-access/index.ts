const PRODUCT_KEY = "stew-captain-form";

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json; charset=utf-8" },
  });

function requiredSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing required secret: ${name}`);
  return value;
}

function authenticatedEmail(request: Request): string | null {
  const authorization = request.headers.get("authorization");
  const token = authorization?.replace(/^Bearer\s+/i, "");
  if (!token) return null;

  try {
    const payloadPart = token.split(".")[1];
    if (!payloadPart) return null;
    const normalized = payloadPart.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
    const payload = JSON.parse(atob(padded)) as { email?: unknown };
    return typeof payload.email === "string" ? payload.email.trim().toLowerCase() : null;
  } catch {
    return null;
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // Supabase verifies the JWT before this function runs (verify_jwt = true).
  const email = authenticatedEmail(request);
  if (!email) return json({ allowed: false, error: "Authenticated email unavailable" }, 401);

  try {
    const supabaseUrl = requiredSecret("SUPABASE_URL");
    const serviceRoleKey = requiredSecret("SUPABASE_SERVICE_ROLE_KEY");
    const query = new URLSearchParams({
      customer_email: `ilike.${email}`,
      product_key: `eq.${PRODUCT_KEY}`,
      status: "eq.active",
      select: "id",
      limit: "1",
    });
    const response = await fetch(`${supabaseUrl}/rest/v1/entitlements?${query}`, {
      headers: {
        apikey: serviceRoleKey,
        authorization: `Bearer ${serviceRoleKey}`,
      },
    });
    if (!response.ok) throw new Error(`Entitlement lookup failed with status ${response.status}`);
    const rows = await response.json() as Array<{ id: string }>;
    return json({ allowed: rows.length === 1 });
  } catch (error) {
    console.error(error instanceof Error ? error.message : "Unknown access-check error");
    return json({ allowed: false, error: "Access check failed" }, 500);
  }
});
