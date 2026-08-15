# Stripe webhook — test foundation only

This function verifies Stripe's raw-body signature, accepts only a paid
`checkout.session.completed` event for the approved $19 USD price, and writes
an idempotent purchase plus entitlement. It is intentionally not deployed.

Required server-side secrets:

- `STRIPE_WEBHOOK_SECRET`: test endpoint signing secret (`whsec_...`).
- `STRIPE_RESTRICTED_KEY`: test restricted key (`rk_test_...`) with read-only
  access to Checkout Sessions so the function can verify line items.
- `STRIPE_STEW_CAPTAIN_PRICE_ID`: the approved test-mode $19 one-time Price ID.
- `SUPABASE_URL`: supplied by Supabase at runtime.
- `SUPABASE_SERVICE_ROLE_KEY`: supplied by Supabase at runtime; never expose it
  to static HTML or commit it to Git.

Before deployment approval:

1. Confirm the migration exists on the test branch and is applied only to the
   intended Supabase test/preview environment.
2. Confirm the approved test Price ID, amount (`1900`), and currency (`usd`).
3. Configure the four secrets above in the test environment.
4. Serve locally with JWT verification disabled for this function and use
   Stripe CLI forwarding to test valid, duplicate, wrong-price, unpaid, and
   invalid-signature cases.
5. Review database rows and logs. Do not add the live webhook endpoint or live
   secrets until the owner explicitly approves deployment.