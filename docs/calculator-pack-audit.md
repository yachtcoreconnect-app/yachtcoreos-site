# Yacht Crew Work & Cost Calculator Pack — Test Audit

Status: test branch only. Do not merge, promote, enable live payments, or publish publicly without Sofya's final approval.

## Canonical test offer

- Product: Yacht Crew Work & Cost Calculator Pack
- Business: SOF YACHT FLOW LLC
- Brand: YachtCoreOS
- Price: $12 USD one-time
- Stripe mode: Sandbox (`livemode: false`)
- Delivery: manual during the controlled launch test
- Package: `YachtCrewCalculatorPack-v1.0.zip`
- SHA-256: `2c7ecdb7716faee2c9c207bb4cfb5c0492d530ff228e831ed59cea5bf921eb99`

## Package contents verified

- `index.html` — offline single-file calculator application
- `START-HERE.txt` — setup and use instructions
- `USAGE-NOTICE.txt` — personal-use and estimate disclaimer

The application includes:

1. Yacht Work Rate Calculator
2. Dockage Cost Estimator
3. Crew Rotation Planner

All calculator inputs and calculations remain client-side. The package requires no account or internet connection after delivery.

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
- Stripe checkout returns to the branch-specific success page.
- The success page clearly states that redirect alone does not prove payment.
- Manual delivery follows `docs/calculator-pack-delivery-runbook.md`.
- The ZIP checksum matches the audited package before every delivery.

## Explicitly excluded

- Live Stripe activation
- Production merge
- Production domain promotion
- Public launch
- Automated email delivery
- Legal approval
