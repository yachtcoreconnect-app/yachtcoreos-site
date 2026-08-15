// Test-only Stripe fulfillment webhook. Do not deploy without owner approval.

const STRIPE_API_VERSION = "2026-06-24.dahlia";
const PRODUCT_KEY = "stew-captain-form";
const EXPECTED_AMOUNT = 1900;
const EXPECTED_CURRENCY = "usd";

type StripeCheckoutSession = {
  id: string;
  object: "checkout.session";
  amount_total: number | null;
  currency: string | null;
  customer: string | null;
  customer_details?: { email?: string | null } | null;
  customer_email: string | null;
  payment_intent: string | null;
  payment_status: "paid" | "unpaid" | "no_payment_required";
};

type StripeEvent = {
  id: string;
  type: string;
  data: { object: StripeCheckoutSession };
};

type Purchase = { id: string };

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

function requiredSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing required secret: ${name}`);
  return value;
}

function constantTimeEqual(left: string, right: string): boolean {
  const encoder = new TextEncoder();
  const a = encoder.encode(left);
  const b = encoder.encode(right);
  let mismatch = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let index = 0; index < length; index++) {
    mismatch |= (a[index % a.length] ?? 0) ^ (b[index % b.length] ?? 0);
  }
  return mismatch === 0;
}

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  return Array.from(new Uint8Array(signature), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function verifyStripeSignature(
  rawBody: string,
  signatureHeader: string,
  webhookSecret: string,
): Promise<void> {
  const fields = signatureHeader.split(",").map((field) => field.trim().split("=", 2));
  const timestamp = fields.find(([key]) => key === "t")?.[1];
  const signatures = fields.filter(([key]) => key === "v1").map(([, value]) => value);
  if (!timestamp || signatures.length === 0) throw new Error("Malformed Stripe-Signature header");

  const timestampSeconds = Number(timestamp);
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(timestampSeconds) || Math.abs(nowSeconds - timestampSeconds) > 300) {
    throw new Error("Stripe signature timestamp is outside the five-minute tolerance");
  }

  const expected = await hmacSha256Hex(webhookSecret, `${timestamp}.${rawBody}`);
  if (!signatures.some((signature) => constantTimeEqual(signature, expected))) {
    throw new Error("Stripe signature mismatch");
  }
}

async function stripeGet(path: string, apiKey: string): Promise<Record<string, unknown>> {
  const response = await fetch(`https://api.stripe.com/v1${path}`, {
    headers: {
      authorization: `Bearer ${apiKey}`,
      "stripe-version": STRIPE_API_VERSION,
    },
  });
  if (!response.ok) throw new Error(`Stripe API request failed with status ${response.status}`);
  return await response.json();
}

async function supabaseRequest(
  path: string,
  serviceRoleKey: string,
  init: RequestInit = {},
): Promise<Response> {
  const supabaseUrl = requiredSecret("SUPABASE_URL");
  return await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: serviceRoleKey,
      authorization: `Bearer ${serviceRoleKey}`,
      "content-type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

async function findPurchase(sessionId: string, serviceRoleKey: string): Promise<Purchase | null> {
  const response = await supabaseRequest(
    `purchases?stripe_checkout_session_id=eq.${encodeURIComponent(sessionId)}&select=id&limit=1`,
    serviceRoleKey,
  );
  if (!response.ok) throw new Error(`Purchase lookup failed with status ${response.status}`);
  const rows = await response.json() as Purchase[];
  return rows[0] ?? null;
}

async function createPurchase(
  session: StripeCheckoutSession,
  eventId: string,
  priceId: string,
  productId: string | null,
  serviceRoleKey: string,
): Promise<Purchase> {
  const response = await supabaseRequest("purchases?on_conflict=stripe_checkout_session_id", serviceRoleKey, {
    method: "POST",
    headers: { prefer: "resolution=ignore-duplicates,return=representation" },
    body: JSON.stringify({
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      stripe_customer_id: session.customer,
      customer_email: session.customer_details?.email ?? session.customer_email,
      product_key: PRODUCT_KEY,
      stripe_product_id: productId,
      stripe_price_id: priceId,
      amount_total: session.amount_total,
      currency: session.currency,
      payment_status: session.payment_status,
      fulfillment_status: "pending",
      stripe_event_id: eventId,
    }),
  });
  if (!response.ok) throw new Error(`Purchase insert failed with status ${response.status}`);
  const rows = await response.json() as Purchase[];
  return rows[0] ?? (await findPurchase(session.id, serviceRoleKey)) ??
    (() => { throw new Error("Purchase was not returned after idempotent insert"); })();
}

async function grantEntitlement(
  purchase: Purchase,
  email: string | null,
  serviceRoleKey: string,
): Promise<void> {
  const entitlement = await supabaseRequest("entitlements?on_conflict=purchase_id", serviceRoleKey, {
    method: "POST",
    headers: { prefer: "resolution=ignore-duplicates,return=minimal" },
    body: JSON.stringify({
      purchase_id: purchase.id,
      product_key: PRODUCT_KEY,
      customer_email: email,
      status: "active",
    }),
  });
  if (!entitlement.ok) throw new Error(`Entitlement insert failed with status ${entitlement.status}`);

  const purchaseUpdate = await supabaseRequest(`purchases?id=eq.${purchase.id}`, serviceRoleKey, {
    method: "PATCH",
    headers: { prefer: "return=minimal" },
    body: JSON.stringify({ fulfillment_status: "fulfilled", fulfilled_at: new Date().toISOString() }),
  });
  if (!purchaseUpdate.ok) throw new Error(`Purchase fulfillment update failed with status ${purchaseUpdate.status}`);
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const signature = request.headers.get("stripe-signature");
    if (!signature) return json({ error: "Missing Stripe-Signature header" }, 400);

    const rawBody = await request.text();
    await verifyStripeSignature(rawBody, signature, requiredSecret("STRIPE_WEBHOOK_SECRET"));
    const event = JSON.parse(rawBody) as StripeEvent;

    if (event.type !== "checkout.session.completed") {
      return json({ received: true, ignored: event.type });
    }

    const session = event.data.object;
    if (session.object !== "checkout.session" || session.payment_status !== "paid") {
      return json({ error: "Checkout Session is not a completed paid session" }, 400);
    }

    const stripeApiKey = requiredSecret("STRIPE_RESTRICTED_KEY");
    const approvedPriceId = requiredSecret("STRIPE_STEW_CAPTAIN_PRICE_ID");
    const lineItems = await stripeGet(`/checkout/sessions/${encodeURIComponent(session.id)}/line_items?limit=10`, stripeApiKey);
    const items = (lineItems.data ?? []) as Array<{ price?: { id?: string; product?: string | null } | null; quantity?: number | null }>;
    const approvedItems = items.filter((item) => item.price?.id === approvedPriceId);
    const validLineItems = items.length === 1 && approvedItems.length === 1 && approvedItems[0].quantity === 1;
    const validAmount = session.amount_total === EXPECTED_AMOUNT && session.currency === EXPECTED_CURRENCY;
    if (!validLineItems || !validAmount) return json({ error: "Checkout Session does not match the approved product" }, 400);

    const serviceRoleKey = requiredSecret("SUPABASE_SERVICE_ROLE_KEY");
    const purchase = await createPurchase(
      session,
      event.id,
      approvedPriceId,
      approvedItems[0].price?.product ?? null,
      serviceRoleKey,
    );
    await grantEntitlement(
      purchase,
      session.customer_details?.email ?? session.customer_email,
      serviceRoleKey,
    );

    return json({ received: true });
  } catch (error) {
    console.error(error instanceof Error ? error.message : "Unknown webhook error");
    return json({ error: "Webhook processing failed" }, 500);
  }
});