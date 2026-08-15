# Yacht Crew Work & Cost Calculator Pack — Test Audit

Status: test branch only. Do not merge, promote, enable live payments, or publish publicly without Sofya's final approval.

## Canonical test offer

- Product: Yacht Crew Work & Cost Calculator Pack
- Business: SOF YACHT FLOW LLC
- Brand: YachtCoreOS
- Price: $12 USD one-time
- Stripe mode: Sandbox (`livemode: false`)
- Delivery: manual during the controlled launch test
- Package: `YachtCrewCalculatorPack-v1.0.1.zip`
- SHA-256: `476b1d8a8965f7c950e03bcabe5de068526ba4b2ae86c2c78c5d7795fecbdcc5`

## Package contents verified

- `index.html` — offline single-file calculator application
- `START-HERE.txt` — setup and use instructions
- `USAGE-NOTICE.txt` — personal-use and estimate disclaimer

The application includes:

1. Yacht Work Rate Calculator
2. Dockage Cost Estimator
3. Crew Rotation Planner

All calculator inputs and calculations remain client-side. The package requires no account or internet connection after delivery.

## Product classification and responsibility boundary

- Yacht Work Rate Calculator — calculation and comparison tool
- Dockage Cost Estimator — calculation and comparison tool
- Crew Rotation Planner — planning and date-projection tool

All three are low-risk productivity tools. They organize user-entered information and return planning estimates; they do not verify inputs, determine compliance, or make professional or operational decisions. The appropriately qualified or licensed person remains responsible for reviewing the information and making every real-world decision within the scope of their authority.

## Stripe test configuration verified

- Product: `prod_V4uxbooPWjhOM0`
- Price: `price_1U4l7yCAmnuwvjycPKsABDVZ`
- Amount: 1200 USD cents
- Type: one-time
- Payment Link: `plink_1U4lnNCAmnuwvjycdCNOjSxV`
- Payment Link active: yes
- Payment Link live mode: no

## Completion standard for this branch

- Dedicated $12 sales preview loads on mobile and desktop.
- Every price and delivery statement is consistent.
- CTA opens the verified Stripe Sandbox Payment Link.
- Stripe displays its verified hosted Sandbox confirmation message.
- A branch-specific success page is staged for later use, but is not configured as the Payment Link return while the Vercel preview remains access-protected.
- Both confirmation surfaces state that redirect or display alone does not prove payment.
- Manual delivery follows `docs/calculator-pack-delivery-runbook.md`.
- The ZIP checksum matches the audited package before every delivery.

## Explicitly excluded

- Live Stripe activation
- Production merge
- Production domain promotion
- Public launch
- Automated email delivery
- Blanket legal-review gate for this low-risk calculator release

This exclusion does not remove the requirements for accurate product claims, a clear delivery/refund policy, reasonable data handling, or final owner approval. A specialist review is still required before any tool is marketed as safety-critical, compliance-determining, medical, navigational, engineering, or other licensed professional guidance.
