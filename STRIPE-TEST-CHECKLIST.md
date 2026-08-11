# Stew–Captain Form Stripe test gate

The GitHub branch intentionally contains no live payment URL.

Before enabling the demo checkout button:

1. In Stripe Dashboard, switch to **Test mode**.
2. Create a one-time product named `Stew–Captain Form — Test Access` for **$19 USD**.
3. Create a test Payment Link for that product.
4. Set the post-payment redirect to the branch preview URL for `thank-you.html`.
5. Set the cancellation/return path to the branch preview URL for `stew-inquiry-demo.html` when the selected Stripe surface supports it.
6. Replace `CHECKOUT_TEST_URL` in `stew-inquiry-demo.html` with the verified test Payment Link and remove `aria-disabled="true"`.
7. Run a Stripe test payment and verify: demo → checkout → thank-you → form → generated brief → copy/download.
8. Confirm the Dashboard shows a **test** payment and no live charge.

Do not add Stripe secret keys, webhook secrets, customer data, or live Payment Links to this branch.
