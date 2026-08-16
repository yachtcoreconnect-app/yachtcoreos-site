// Test/staging Stripe webhook for YachtCoreOS products.
// Stripe calls this endpoint without a Supabase JWT; authenticity is established
// exclusively by verification of the raw-body Stripe-Signature header.

const STRIPE_API_VERSION = "2026-06-24.dahlia";
const PRODUCTS = {
  "price_1U4l7yCAmnuwvjycPKsABDVZ": {
    key: "yacht-crew-calculator-pack",
    amount: 1200,
    currency: "usd",
  },
} as const;

type Session = {
  id: string; object: "checkout.session"; amount_total: number | null;
  currency: string | null; customer: string | null; customer_email: string | null;
  customer_details?: { email?: string | null } | null;
  payment_intent: string | null; payment_status: string;
};
type Event = { id: string; type: string; data: { object: Session } };

const json = (body: Record<string, unknown>, status = 200) => new Response(
  JSON.stringify(body),
  { status, headers: { "content-type": "application/json; charset=utf-8" } },
);

function secret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing required secret: ${name}`);
  return value;
}

async function signature(raw: string, header: string, key: string) {
  const parts = header.split(",").map((part) => part.trim().split("=", 2));
  const timestamp = parts.find(([name]) => name === "t")?.[1];
  const supplied = parts.filter(([name]) => name === "v1").map(([, value]) => value);
  if (!timestamp || supplied.length === 0) throw new Error("Malformed Stripe signature");
  if (Math.abs(Math.floor(Date.now() / 1000) - Number(timestamp)) > 300) {
    throw new Error("Expired Stripe signature");
  }
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw", encoder.encode(key), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const bytes = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(`${timestamp}.${raw}`));
  const expected = [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
  const valid = supplied.some((candidate) => {
    if (candidate.length !== expected.length) return false;
    let mismatch = 0;
    for (let i = 0; i < expected.length; i++) mismatch |= candidate.charCodeAt(i) ^ expected.charCodeAt(i);
    return mismatch === 0;
  });
  if (!valid) throw new Error("Stripe signature mismatch");
}

async function stripe(path: string) {
  const response = await fetch(`https://api.stripe.com/v1${path}`, {
    headers: {
      authorization: `Bearer ${secret("STRIPE_RESTRICTED_KEY")}`,
      "stripe-version": STRIPE_API_VERSION,
    },
  });
  if (!response.ok) throw new Error(`Stripe API ${response.status}`);
  return await response.json();
}

async function database(path: string, init: RequestInit = {}) {
  const serviceKey = secret("SUPABASE_SERVICE_ROLE_KEY");
  return await fetch(`${secret("SUPABASE_URL")}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: serviceKey,
      authorization: `Bearer ${serviceKey}`,
      "content-type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

async function fulfill(event: Event, session: Session) {
  const lineItems = await stripe(`/checkout/sessions/${encodeURIComponent(session.id)}/line_items?limit=10`);
  const items = (lineItems.data ?? []) as Array<{
    quantity?: number | null;
    price?: { id?: string; product?: string | null } | null;
  }>;
  if (items.length !== 1 || items[0].quantity !== 1 || !items[0].price?.id) {
    throw new Error("Checkout does not contain one approved item");
  }

  const priceId = items[0].price.id;
  const dynamicStewPrice = Deno.env.get("STRIPE_STEW_CAPTAIN_PRICE_ID");
  const product = priceId === dynamicStewPrice
    ? { key: "stew-captain-form", amount: 1900, currency: "usd" }
    : PRODUCTS[priceId as keyof typeof PRODUCTS];
  if (!product || session.amount_total !== product.amount || session.currency !== product.currency) {
    throw new Error("Checkout does not match the approved product registry");
  }

  const email = session.customer_details?.email ?? session.customer_email;
  if (!email) throw new Error("Checkout has no delivery email");

  const purchaseResponse = await database("purchases?on_conflict=stripe_checkout_session_id", {
    method: "POST",
    headers: { prefer: "resolution=ignore-duplicates,return=representation" },
    body: JSON.stringify({
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      stripe_customer_id: session.customer,
      customer_email: email.toLowerCase(),
      product_key: product.key,
      stripe_product_id: items[0].price.product ?? null,
      stripe_price_id: priceId,
      amount_total: session.amount_total,
      currency: session.currency,
      payment_status: session.payment_status,
      fulfillment_status: "pending",
      stripe_event_id: event.id,
    }),
  });
  if (!purchaseResponse.ok) throw new Error(`Purchase write ${purchaseResponse.status}`);
  let purchases = await purchaseResponse.json() as Array<{ id: string }>;
  if (purchases.length === 0) {
    const lookup = await database(
      `purchases?stripe_checkout_session_id=eq.${encodeURIComponent(session.id)}&select=id&limit=1`,
    );
    if (!lookup.ok) throw new Error(`Purchase lookup ${lookup.status}`);
    purchases = await lookup.json();
  }
  const purchase = purchases[0];
  if (!purchase) throw new Error("Purchase was not persisted");

  const entitlement = await database("entitlements?on_conflict=purchase_id", {
    method: "POST",
    headers: { prefer: "resolution=ignore-duplicates,return=minimal" },
    body: JSON.stringify({
      purchase_id: purchase.id,
      product_key: product.key,
      customer_email: email.toLowerCase(),
      status: "active",
    }),
  });
  if (!entitlement.ok) throw new Error(`Entitlement write ${entitlement.status}`);

  const completed = await database(`purchases?id=eq.${purchase.id}`, {
    method: "PATCH",
    headers: { prefer: "return=minimal" },
    body: JSON.stringify({ fulfillment_status: "fulfilled", fulfilled_at: new Date().toISOString() }),
  });
  if (!completed.ok) throw new Error(`Fulfillment update ${completed.status}`);
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const header = request.headers.get("stripe-signature");
    if (!header) return json({ error: "Missing Stripe-Signature" }, 400);
    const raw = await request.text();
    await signature(raw, header, secret("STRIPE_WEBHOOK_SECRET"));
    const event = JSON.parse(raw) as Event;
    if (event.type !== "checkout.session.completed") return json({ received: true, ignored: event.type });
    const session = event.data.object;
    if (session.object !== "checkout.session" || session.payment_status !== "paid") {
      return json({ error: "Checkout is not paid" }, 400);
    }
    await fulfill(event, session);
    return json({ received: true });
  } catch (error) {
    console.error(error instanceof Error ? error.message : "Unknown webhook error");
    return json({ error: "Webhook processing failed" }, 500);
  }
});
