# Calculator Pack Manual Test Delivery Runbook

Use this process only for Stripe Sandbox testing until a production fulfillment system is separately approved.

## Before the test

1. Confirm the checkout URL contains `buy.stripe.com/test_`.
2. Confirm the Stripe Payment Link reports `livemode: false` and amount `1200` USD cents.
3. Confirm the package filename is `YachtCrewCalculatorPack-v1.0.1.zip`.
4. Verify its SHA-256 checksum is:

   `476b1d8a8965f7c950e03bcabe5de068526ba4b2ae86c2c78c5d7795fecbdcc5`

## Verify the test order

1. Open Stripe in Sandbox mode.
2. Locate the completed Checkout Session or payment associated with the buyer email.
3. Confirm status is paid/complete, currency is USD, and amount is $12.00.
4. Confirm the line item is Yacht Crew Work & Cost Calculator Pack.
5. Do not fulfill from the success-page screenshot alone.

The test Payment Link currently uses Stripe's hosted confirmation. Do not configure a temporary Vercel share URL as the redirect target because that URL expires.

## Deliver manually

1. Create a new email from `yachtcoreconnect@yachtcoreos.com` to the email recorded by Stripe.
2. Subject: `Your YachtCoreOS Calculator Pack — test delivery`
3. Explain that this is a Sandbox test and no real payment was collected.
4. Attach `YachtCrewCalculatorPack-v1.0.1.zip`.
5. Include the opening instructions from `START-HERE.txt`.
6. Send only after the Stripe order has been independently verified.

## Record the test

Record the test date, Stripe Checkout Session ID, recipient email, package version, checksum result, delivery time, and any issue. Do not store card details.

## Failure handling

- Payment incomplete: do not deliver.
- Wrong amount or product: do not deliver; investigate the Payment Link.
- Checksum mismatch: do not deliver; replace the package with the audited version.
- Email bounce: verify the checkout email before resending.
- Duplicate session: deliver once and record both session IDs.
