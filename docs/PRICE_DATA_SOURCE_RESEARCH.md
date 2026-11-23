# Price Intelligence — source feasibility

Research date: 23 November 2026.

## Decision

Do not enable an external automated price feed in the MVP until there is a source with both:
1. a continuing free access tier suitable for the app's expected usage; and
2. explicit permission to reuse and display the data in ListACT.

No such source was verified in this research pass. The application therefore keeps manual personal prices and the Price Intelligence schema dormant. It must not invent or silently substitute prices.

## Sources reviewed

### Oferoo

- Product/API page: https://oferoo.ro/api-preturi
- Describes a one-time API trial of 500 credits, then paid access.
- The page lists a Starter plan at €29/month (price shown on 16 November 2026), plus prepaid credit packs.
- The website itself is free, but its API is not a continuing free tier.
- The page describes source-level product/chain prices and barcodes; it does not, by itself, establish an unrestricted redistribution licence for ListACT.

### Numbeo

- API page: https://www.numbeo.com/api/supermarket-prices-api
- The Supermarket Prices API is part of paid Data API plans.
- Not suitable under the no-paid-API requirement.

### Kaufland

- Terms reviewed: https://content.kaufland.com/ro/ro/ssc12/terms_of_use.html
- The reviewed terms concern Kaufland Card XTRA and specify personal-use restrictions for that service.
- They are not a blanket permission for third-party automated collection or redistribution of product prices.

### Carrefour

- Privacy policy reviewed: https://carrefour.ro/politica-confidentialitate
- This is a privacy notice, not a licence granting reuse of catalogue or price data.
- No public, free, reusable price API was verified from this source.

## Implementation guardrails

- Do not scrape retailer sites or bypass technical controls.
- A source remains disabled unless reuse rights and access conditions are verified and recorded in `price_sources`.
- Preserve source URL, store/city, observation time, match type, and sample count for every estimate.
- City-specific data must not be replaced with national or other-city data without an explicit, visible label.
- Unpriced items remain excluded from the numeric basket total and are counted separately.
- Manual personal prices remain available independently of online observations.
