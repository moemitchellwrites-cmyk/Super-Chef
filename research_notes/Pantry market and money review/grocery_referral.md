# Grocery affiliate and referral economics for a recipe app hand-off (US, as of 2026-10-08)

Reading note for the report writer: every figure below carries its source and, where the source gives one, its date. "Not found" means I looked and could not find a citable figure; it does not mean the figure is zero. Affiliate directories (Referly, FlexOffers listings, LinkClicky, Lasso) are secondary sources and are marked as such. Several pages were read through a summarising fetch tool, so quotations are limited to the phrases shown in quotation marks.

## 1. Instacart: Developer Platform (IDP) and affiliate programme

### Takeaway
Instacart is the only large programme built for exactly this hand-off: an API call returns a link to an Instacart-hosted recipe or shopping-list page, no partner-side user account is involved, and approved partners are paid through Impact. The commission rate is not published in the developer docs; the only primary-source figure is 3% of qualifying purchases on Instacart's own affiliate (Tastemakers) page, and one Instacart page says new IDP applications are currently closed, which must be verified before anything is planned around it.

### Cited Findings
- IDP launched the week of 27 March 2024 with launch partners New York Times Cooking, WeightWatchers and GE Appliances; other named partners included Biocoach, DinnerTime, EatLove, eMeals, Foodsmart, Innit, Intent, Jow, Jupiter, Maple, Northfork, Relish and SmartCommerce. Instacart described monetisation options as affiliate commissions and targeted ad placements, with no fee to join — [Marketing Dive, 2024-03-27](https://www.marketingdive.com/news/instacart-developer-platform-weight-watchers-ge-appliances/711524/)
- The Developer Platform API docs list three public API references: Create Recipe Pages, Shopping Lists (create a shopping list page), and Nearby Retailers (by postal code and country code) — [Instacart Developer Platform docs](https://docs.instacart.com/developer_platform_api/)
- Public API developers do not receive Instacart data; they receive a link to an Instacart-hosted landing page that handles ingredient matching and checkout — [Instacart, IDP business page](https://company.instacart.com/business/developers)
- Scale claimed by Instacart: catalogue of over 1.4B items, 1,800 retail banners, 85,000 store locations, about 600,000 shoppers — [Instacart, IDP business page](https://company.instacart.com/business/developers)
- Eligibility stated on the IDP business page: 18 or older, and a registered business or resident of the US or Canada; applicant supplies contact and business information, a development overview and intended use case, and agrees to IDP terms — [Instacart, IDP business page](https://company.instacart.com/business/developers)
- The same page states that applications are currently closed with no waitlist ("check back later"), as read on 2026-10-08. This conflicts in spirit with developer docs that were still being updated with an approval process in June 2026 (next bullets), so treat it as needing direct confirmation — [Instacart, IDP business page](https://company.instacart.com/business/developers); compare [IDP changelog](https://docs.instacart.com/developer_platform_api/api/changelog)
- How partners are paid: "Developers with a live integration can sign up as affiliate partners and earn commissions on conversion events", such as completed Instacart orders from the partner app or site, or new user sign-ups. Rate not stated — [Instacart, IDP business page](https://company.instacart.com/business/developers)
- Payment mechanics: partners apply to the affiliate programme through Impact; Impact tracks conversions and pays commission on orders attributed to the integration. Sign-up links and programme terms are emailed to active partners and are not public. Tracking parameters are appended automatically to the URL the API returns (example shows `utm_medium=affiliate`, `utm_term=partnertype-mediapartner`, `utm_content=campaignid-..._partnerid-...`); partners must not hardcode them. Setup takes 24 to 48 hours after the Impact partner ID is issued — [IDP docs, Conversions and payments](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/conversions_and_payments)
- The example attribution URL contains a campaign id and partner id only; no end-user identifier appears in it — [IDP docs, Conversions and payments](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/conversions_and_payments)
- Approval: the developer tests with a development key, then requests a production key, which stays "Pending approval" until Instacart reviews "your integrated app or website" (so an app alone is a recognised integration surface). On approval the key goes active and the developer receives an invitation to the Impact.com affiliate programme — [IDP docs, Approval process](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/approval_process)
- Pre-launch checklist (updated 18 June 2026): submit a short screen recording of the integration; Instacart contacts the developer within 5 business days; the call to action must use approved text ("Shop ingredients" or "Shop on Instacart"), approved themes, a 46px-tall button with the full-colour Instacart logo; copy may not say "Free Delivery", "Partner" or "Partnership", may not describe Instacart as a grocery store or delivery service, and may not quote delivery speeds. The checklist says nothing about user accounts or user identifiers — [IDP docs, Pre-launch checklist](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/pre-launch_checklist)
- 2025 to 2026 changes from the changelog: Impact replaced Tastemakers for IDP conversion tracking (entry of 7 Nov 2024; Impact instructions added 29 Jan 2025; Tastemakers step removed 31 Mar 2025); Nearby Retailers API and preferred-retailer option added 17 Apr 2025; MCP tutorial for AI agents added 18 Sep 2025; UPC support added 18 Sep 2025; partner messaging guidelines added 15 Sep 2025; CTA buttons redesigned after A/B testing 4 Feb 2026; on 18 June 2026 conversion tracking and affiliate payments became "an optional final step after approval" — [IDP changelog](https://docs.instacart.com/developer_platform_api/api/changelog)
- Instacart's own affiliate page (Tastemakers, described as a "pilot program"): 3% commission on qualifying purchases made through the creator's shoppable links or recipe webpage; must be 18+ and a legal US resident; a creator's own recipe website must use standard recipe schema to be linked; commission may change at any time with advance notice. Cookie window and new-customer payout not stated. Page read 2026-10-08; it carries no date — [Instacart affiliate page](https://instacart.com/affiliate)
- Secondary, conflicting figures: a directory lists "up to $10 CPA per new customer order", a 7-day cookie, a one-time (not recurring) commission, and notes other unnamed sources quote 5% on orders; the page is undated and says to confirm the rate in Impact — [Referly listing, undated](https://marketplace.referly.so/affiliate-programs/instacart)
- An IDP partner's own explainer (Jupiter, dated 21 July 2026) declines to state a rate, saying structures vary between a flat per-new-customer payout and a small percentage of qualifying orders; it reports the commission base is typically the full qualifying order (not only recipe items), exclusions of alcohol, restaurant orders, prescriptions and gift cards, and payout about 55 days after the month of purchase via Impact — [Jupiter blog, 2026-07-21](https://www.jupiter.co/blog/instacart-affiliate-for-food-creators)

### Inferences
- The IDP link-out model fits the brief's constraints as documented: the app sends ingredients to Instacart's API and opens the returned URL; nothing in the docs requires the partner to hold user accounts or pass a user id. The one architectural catch is the API key: it has to be held server-side, so the existing judge proxy (or a second small endpoint) would need to mint the link, or links for each fixed recipe could be generated once and shipped as static URLs. Whether pre-generated URLs expire was not checked.
- The primary-source rate (3%) and the directory rate ($10 per new customer) may both be true for different partner types or dates. For a revenue model, 3% of order value is the only figure with an Instacart-owned source; the new-customer CPA should be treated as unconfirmed.
- Specialty Sichuan ingredients (doubanjiang, Chinkiang vinegar) are only on Instacart where a local retailer on the platform stocks them; ingredient matching quality for this cuisine is untested and is the thing Instacart itself reviews at approval.

### Gaps
- The actual IDP affiliate rate, attribution window, and whether existing Instacart customers' orders earn anything: not public; emailed to approved partners only.
- Whether IDP applications are open today: one Instacart page says closed; not independently confirmed. The "Get an API key" docs page returned a 404 at the URL tried.
- Whether an IDP partner must have a website (as opposed to only an app): docs say "app or website" but the Impact application itself may ask for a web property; not confirmed.
- Any disclosed IDP partner earnings: not found.

## 2. Amazon: Associates rates for grocery, Fresh, Whole Foods; cart prefill; app rules

### Takeaway
Amazon pays 1% on Grocery and 1% on Amazon Fresh, plus a $1 bounty for an Amazon Fresh first purchase, and it does not allow Associates links in a mobile app without separate written approval. For a link-out from an iOS app this is the weakest of the big three on both rate and friction.

### Cited Findings
- Amazon's Standard Commission Income Statement lists Amazon Fresh at 1.00% and Grocery at 1.00% (also Health & Personal Care 1.00%); Kitchen and Physical Books 4.50%; "All Other Categories" 4.00%; alcoholic beverages and restaurant-prepared food 0%. The page shows no effective date (footer copyright 2025), read 2026-10-08 — [Amazon Associates, Standard Commission Income Statement](https://affiliate-program.amazon.com/help/node/topic/GRXPHT8U84RAYDXZ?lang=en)
- Bounties on the same statement: Amazon Fresh First Purchase $1.00 (bonus event); Prime Free Trial $3.00; EBT card registration $2.00 — [Amazon Associates, Standard Commission Income Statement](https://affiliate-program.amazon.com/help/node/topic/GRXPHT8U84RAYDXZ?lang=en)
- Whole Foods Market does not appear as a line on the statement — [Amazon Associates, Standard Commission Income Statement](https://affiliate-program.amazon.com/help/node/topic/GRXPHT8U84RAYDXZ?lang=en)
- Amazon Fresh was cut from 3% to 1% in April 2020 (secondary source, page updated 17 July 2026). Attribution: 24 hours from click to add an item to cart; a carted item bought within 90 days can still earn — [Lasso, updated 2026-07-17](https://getlasso.co/amazon-affiliate-commission-rate/)
- Mobile apps: "Approved mobile apps can participate in the Amazon Associates program"; apps earn commission "differently than links on websites" — [Amazon Associates help, links in a mobile app](https://affiliate-program.amazon.com/help/node/topic/GQZMCDD9PB7CXV7N)
- Mobile apps are not approved to carry advertising links to Amazon unless the associate signs an amendment; using Product Advertising content in an application designed for handheld devices needs Amazon's prior written approval; unapproved in-app links are treated as fraud — [Amazon Associates help, PA-API in a mobile app](https://affiliate-program.amazon.com/help/node/topic/GFP8AD2UDZDQTJPP)
- Evidence that Fresh recipe carts can be driven by an Associates tag: the creator tool GRO's "Shop the Recipe" earns affiliate income only through Amazon Fresh (not Instacart), using the creator's Associates Store ID. No rates or earnings disclosed; undated — [GRO help centre](https://help.gro.co/en/articles/9917387-how-to-earn-affiliate-income-with-shop-the-recipe)

### Inferences
- At 1%, a $100 Fresh order yields $1.00, plus $1.00 once if it is the customer's first Fresh purchase. Specialty items bought on Amazon.com proper as Grocery also earn 1%.
- The app-approval amendment is a real gate for an app with no website and no accounts; this is a reason to rank Amazon behind Instacart, not a reason it is impossible.

### Gaps
- Whether a multi-item Amazon Fresh cart can be prefilled by a public link format: not confirmed from an Amazon source. GRO's tool implies some mechanism exists; the mechanism was not documented in what I read.
- Whole Foods Market commission treatment: not found on the rate card.
- The terms of the mobile-app amendment and how app commissions differ: not found.

## 3. Walmart: affiliate and creator programmes, grocery rate

### Takeaway
Walmart runs two programmes on Impact (Affiliate for publishers, Creator for social accounts) and does not publish a category rate card; a grocery rate could not be confirmed from any reliable source. The attribution window is 14 days.

### Cited Findings
- Walmart does not publish per-category rates; they are visible after approval. The only public figure found by this source was an 11% time-limited promotional banner for summer home decor. Third-party rate tables are unsourced and contradict each other — [CreatorFlow, updated 2026-08-21](https://creatorflow.so/blog/walmart-creator-program/)
- Attribution window 14 days, covering anything bought at Walmart in that window; a later click on another affiliate's link takes precedence. Commissions lock for 30 days; payments monthly through Impact — [CreatorFlow, updated 2026-08-21](https://creatorflow.so/blog/walmart-creator-program/)
- Grocery purchases are reported to count within the 14-day window, with no rate given. Excluded: Sam's Club, pharmacy, travel, financial services, tires, gift cards — [CreatorFlow, updated 2026-08-21](https://creatorflow.so/blog/walmart-creator-program/)
- Walmart Creator requires 18+, US residence, a US bank account, and (per terms) 1,000 followers across connected social accounts, with manual review; the Walmart Affiliate Program (affiliates.walmart.com, terms updated April 2026) is built for website publishers and states no follower minimum; Creator terms updated June 2026 — [CreatorFlow, updated 2026-08-21](https://creatorflow.so/blog/walmart-creator-program/)
- Northfork's shoppable-recipe product was described in mid-2025 as having only Walmart in testing (source is a competitor, SideChef) — [SideChef comparison, 2025-06-05](https://business.sidechef.com/recipe-platform/shoppable-recipe-button-comparison)

### Inferences
- Walmart Creator is a poor fit (social-follower requirement). The Affiliate Program is the relevant door, and it is oriented to websites; an app-only publisher's acceptance is uncertain.

### Gaps
- Walmart grocery commission rate (2025 or 2026): not found from a primary or reliable source.
- Whether Walmart offers any public recipe-to-cart link or API for third-party apps: not found.
- Whether the Affiliate Program accepts an app with no website: not found.

## 4. Kroger: API and affiliate terms

### Takeaway
The only Kroger affiliate figure found is 3.2% on Kroger "Ship" orders with a 7-day cookie, from a FlexOffers listing last updated January 2025; nothing was found that pays on Kroger pickup or delivery grocery orders.

### Cited Findings
- Kroger affiliate programme on FlexOffers: 3.2% of SHIP orders, 7-day cookie; listing last updated 28 January 2025 (older than the 2025-2026 confirmation bar for anything after that date) — [FlexOffers, Kroger listing, 2025-01-28](https://www.flexoffers.com/affiliate-programs/kroger-affiliate-program)
- Third-party open-source tools (a Kroger CLI, an MCP server, a `kroger-cart` Python package) exist that add items to a Kroger cart through Kroger's public developer API, which indicates a cart-add API is available to outside developers — [kroger-cart on PyPI](https://pypi.org/project/kroger-cart/); [kroger-mcp on GitHub](https://github.com/CupOfOwls/kroger-mcp)

### Inferences
- A Kroger cart-add API by its nature acts on a signed-in Kroger customer's cart, which implies an OAuth sign-in to Kroger inside the hand-off. That is the user's Kroger account, not a Pantry account, but it is heavier than a link-out. This is inferred from how the tools are described, not read from Kroger's terms.

### Gaps
- Kroger developer portal terms (commercial use, rate limits, whether any referral payment attaches to API-driven carts): not read; not found in search.
- Whether the 3.2% Ship programme is still live in October 2026: not confirmed.
- Kroger's shoppable-recipe partners: not found beyond general coverage.

## 5. Asian and specialty grocers

### Takeaway
Weee! has an affiliate programme (FlexOffers lists a flat $8 per new-customer order, 7-day cookie, April 2026) and is the best-stocked national source for the Sichuan pantry; The Mala Market shows no affiliate or referral programme on its site; the other figures found are old or from directories.

### Cited Findings
- Weee! runs its own affiliate programme page ("You could earn $3,000 per month"; affiliates "Earn from qualified purchases and new referrals"); it states no rate, cookie window, network or eligibility, and directs questions to affiliate@sayweee.com — [Weee! affiliates page](https://www.weee.com/company/affiliates-en)
- Weee! on FlexOffers: flat $8 payout per new customer order, 7-day cookie, status Active; listing published 28 April 2026, updated 29 April 2026; network-reported earnings per click $0.11 over 90 days — [FlexOffers, Weee! listing, 2026-04-29](https://www.flexoffers.com/affiliate-programs/sayweee-com-affiliate-program/)
- Yamibuy on FlexOffers: $4 per new customer sale (online or in-app), 2-day cookie; the listing says the programme is not currently offered in FlexOffers' system; last updated 23 February 2025 — [FlexOffers, Yamibuy listing, 2025-02-23](https://www.flexoffers.com/affiliate-programs/yamibuy-affiliate-program)
- Fly By Jing: 7% per sale, 30-day cookie, via ShareASale, per a directory last updated 10 March 2024 (not confirmed in 2025 or 2026; ShareASale has since been folded into Awin, and a search result shows an Awin merchant profile that I did not open) — [LinkClicky, 2024-03-10](https://linkclicky.com/affiliate-program/fly-by-jing/)
- The Mala Market: the site's About page and navigation mention no affiliate, referral or rewards programme; the only trade-facing item is a "Wholesale (Bulk)" collection in the Shop menu — [The Mala Market, About](https://themalamarket.com/pages/about-us-1)

### Inferences
- Weee!'s $8 new-customer bounty is a one-time payment per referred customer; nothing found says repeat orders pay. For a game whose players may already shop at Weee!, the yield depends on the share who are new to it.
- The Mala Market is a small owner-run importer; with no public programme, any arrangement would be a direct conversation (for example a discount code or a negotiated referral), which cannot be sized from public information.

### Gaps
- Weee! terms from Weee! itself (rate, new versus existing customers, credits versus cash for affiliates): not public on its page. Weee!'s consumer refer-a-friend credit terms were not researched.
- H Mart online and Umamicart affiliate programmes: not found. Whether Umamicart is still operating was not checked.
- Fly By Jing current rate on Awin: not confirmed.
- Whether Weee!'s affiliate links deep-link to a prefilled cart or product list: not found.

## 6. Aggregators and shoppable-recipe middleware

### Takeaway
The middleware companies earn mainly from brands and retailers (retail media and sponsored-product placement inside recipes) rather than from affiliate commission, and none discloses revenue per user, per order, or a full view-to-order conversion rate. No recipe app's affiliate earnings from grocery hand-off were found in public.

### Cited Findings
- Chicory reports about $30 average basket value and about 10 items carted per recipe through its shoppable-recipe button, and that 33% of traffic it sent to a retail partner came from new and lapsed shoppers; the post is dated 6 May with the year inferred as 2021 — [Chicory blog](https://chicory.co/blog-feed/why-shoppability-is-a-worthwile-investment)
- Chicory's campaign case study for a grocery pickup client reports $426K incremental sales and a $4.26 return on ad spend, i.e. its revenue is advertiser-funded media — [Chicory blog](https://chicory.co/blog-feed/why-shoppability-is-a-worthwile-investment)
- Chicory pays publishers on a net-60 schedule for "Chicory Premium" campaign earnings, delivered through ad networks such as Mediavine; the basis of payment (CPM, share, per click) is not stated — [Mediavine help, Chicory Ads FAQ](https://help.mediavine.com/chicory-ads-faq)
- A SideChef comparison of eight providers (Adimo, Chicory, Samsung Food/Whisk, Pear Commerce, Northfork, Click2Cart/SmartCommerce, Destini, SideChef; dated 5 June 2025) characterises them as brand- and retailer-funded: several push sponsored products into the cart; Northfork sells API infrastructure to retailers and content platforms; Samsung Food is "not an ad-tech platform" and shoppable recipes "don't seem to be a primary focus" after the Samsung acquisition. No fees or commissions are disclosed for any provider. The author is one of the providers compared — [SideChef comparison, 2025-06-05](https://business.sidechef.com/recipe-platform/shoppable-recipe-button-comparison)
- Jow, eMeals, Relish and Northfork were named as Instacart Developer Platform integrations at launch, which places them on Instacart's affiliate-commission and ad-placement model for that channel — [Marketing Dive, 2024-03-27](https://www.marketingdive.com/news/instacart-developer-platform-weight-watchers-ge-appliances/711524/)
- GRO (creator tool) routes recipe carts to Amazon Fresh with the creator's own Associates tag; creators keep the Amazon commission — [GRO help centre](https://help.gro.co/en/articles/9917387-how-to-earn-affiliate-income-with-shop-the-recipe)

### Inferences
- The absence of any published affiliate earnings from this whole category, alongside business models built on brand money, suggests commission on hand-offs is not what sustains these companies. That is an inference from silence and from how they describe themselves, not a disclosed fact.
- A single-developer game cannot sell retail media, so the brand-funded model is not available at Pantry's scale; only the affiliate line is.

### Gaps
- Revenue per user, per order, or commission received by Whisk/Samsung Food, Chicory, Northfork, Fexy/Relish, SideChef, Jow, eMeals or Mealime: not found.
- How Mealime and eMeals split revenue between subscriptions and grocery referral: not found.
- Any creator or recipe app publishing actual Instacart or Walmart affiliate earnings: not found.

## 7. Funnel numbers and basket size

### Takeaway
No reliable public figure was found for the share of recipe viewers who tap a shop button, or the share of those who complete an order; the only hard numbers are vendor case-study fragments and Chicory's roughly $30 recipe basket. A revenue-per-1,000-views estimate therefore has to rest on assumed click and order rates, stated as assumptions.

### Cited Findings
- Recipe basket through a shoppable button: about $30 and about 10 items per recipe (Chicory, circa 2021) — [Chicory blog](https://chicory.co/blog-feed/why-shoppability-is-a-worthwile-investment)
- Chicory/Bob's Red Mill campaign: 0.15% click-through rate (described as above an unstated industry average) and a 66% add-to-cart rate whose denominator is not given (most plausibly of those who clicked). No dates — [CaseStudies.com, Chicory / Bob's Red Mill](https://www.casestudies.com/company/chicory/case-study/bobs-red-mill-achieves-66-add-to-cart-rate-with-chicory)
- SideChef claims "3x higher conversion" for shoppable recipes versus shopping individual products (its internal data, 2024; funnel stage unspecified) — [SideChef, 2025-04-15](https://business.sidechef.com/recipe-platform/shoppable-recipe-button)
- SideChef cites Instacart for recipe-linked orders converting "20% better" than search-driven purchases, and a Grocery Shopii pilot for a 30% larger basket when full-meal recipes are carted (both third-hand) — [SideChef comparison, 2025-06-05](https://business.sidechef.com/recipe-platform/shoppable-recipe-button-comparison)
- MikMak case study gives only relative lifts against an undisclosed "shoppable recipe benchmark" (5.7x conversion), so no absolute rate — [MikMak case study](https://www.mikmak.com/case-studies/food-beverage-brand)
- US online grocery context, August 2026 (Brick Meets Click via Talk Business, 24 Sept 2026): online grocery orders up nearly 25% year on year; 60% of households bought groceries online that month; 81% have ever done so; average order value "basically flat"; delivery drove about three-quarters of order-frequency growth — [Talk Business & Politics, 2026-09-24](https://talkbusiness.net/2026/09/august-online-grocery-sales-up-almost-25/)
- Weee! network-reported earnings per click on FlexOffers: $0.11 over 90 days (a real, if thin, cross-publisher yield figure per outbound click) — [FlexOffers, Weee! listing, 2026-04-29](https://www.flexoffers.com/affiliate-programs/sayweee-com-affiliate-program/)

### Inferences
- Illustrative arithmetic using only sourced inputs, to show the order of magnitude rather than to forecast: at Instacart's published 3%, a $30 recipe basket earns $0.90 per completed order; a $100 full-shop order earns $3.00. At Amazon's 1%, the same orders earn $0.30 and $1.00. A Weee! new-customer order earns a flat $8 once.
- If the Weee! $0.11 earnings-per-click figure were representative, 1,000 recipe views with an assumed 5% tap-through (an assumption, not a sourced rate) would yield 50 clicks and about $5.50. With Instacart at 3%, reaching the same $5.50 from 50 clicks would need roughly six $30 orders, i.e. about 12% of clickers completing an order. These are sensitivity checks; the tap-through and order rates are unknown.
- The 0.15% CTR in the Chicory case is an ad-unit rate on publisher pages, not the tap rate on a "shop this recipe" button shown at the end of a round the player just cooked; it should not be used as Pantry's click rate.

### Gaps
- Share of recipe viewers who tap an add-to-cart or shop button, from a neutral source: not found.
- Share of cart hand-offs that become completed orders: not found.
- Average US online grocery order value in dollars by delivery, pickup and ship-to-home for 2026: not found in the sources I could open (Brick Meets Click publishes it; the Digital Commerce 360 and Blue Book pages carrying it could not be fetched).

## 8. Apple App Store rules

### Takeaway
Linking out of an iOS app to buy physical groceries is not only allowed without Apple commission, it is the required route: guideline 3.1.3(e) says physical goods and services consumed outside the app must use purchase methods other than in-app purchase. No guideline text restricting affiliate links for physical goods was found.

### Cited Findings
- Guideline 3.1.3(e), Goods and Services Outside of the App: "If your app enables people to purchase physical goods or services that will be consumed outside of the app, you must use purchase methods other than in-app purchase to collect those payments, such as Apple Pay or traditional credit card entry." Read 2026-10-08 — [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Guideline 3.1.1(a) concerns links to buy digital content; in the United States storefront, entitlements "are not required for developers to include buttons, external links, or other calls to action" — [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Guideline 3.2.2(i) bars "creating an interface for displaying third-party apps, extensions, or plug-ins similar to the App Store"; this concerns app catalogues, not links to a grocery retailer — [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- No mention of affiliate links was found in the first 100,000 characters of the guidelines page; the final ~19,000 characters (later sections, after 3.x) were not read — [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- Pantry never collects payment at all under the link-out design (the grocer does, on its own site or app), so 3.1.3(e)'s payment-method rule is satisfied trivially and no Apple commission applies to the grocery order.
- The affiliate relationship should be disclosed to the player in plain words for FTC endorsement-rule reasons; this is general US practice and was not researched here.

### Gaps
- Whether Apple's guidelines say anything specific about affiliate links to physical-goods retailers in the unread tail of the page: not confirmed (none known).
- App privacy label implications of opening an affiliate-tagged URL (the retailer, not the app, sets cookies): not researched.

## 9. Programme requirements: website, traffic minimums, user identifiers

### Takeaway
Instacart's IDP explicitly reviews an "app or website" and its documented attribution uses partner and campaign ids only; Amazon requires a signed amendment for apps; Walmart's creator track requires 1,000 social followers; none of the documents read requires passing an end-user identifier.

### Cited Findings
- Instacart IDP reviews "your integrated app or website"; requires a developer account, a demo recording, compliant CTA, and (for payments) an Impact account — [IDP docs, Approval process](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/approval_process); [IDP docs, Pre-launch checklist](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/pre-launch_checklist)
- Instacart attribution parameters shown are partner id and campaign id; business details given to Impact are used by Impact to list the business in its marketplace — [IDP docs, Conversions and payments](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/conversions_and_payments)
- Instacart Tastemakers (creator track): 18+, US resident; own recipe website needs standard recipe schema to be linked — [Instacart affiliate page](https://instacart.com/affiliate)
- Instacart affiliate via Impact, per an IDP partner: no follower minimum; approval depends on family-friendly content — [Jupiter blog, 2026-07-21](https://www.jupiter.co/blog/instacart-affiliate-for-food-creators)
- Amazon: apps need Amazon's prior written approval and a signed amendment before carrying Associates links — [Amazon Associates help, PA-API in a mobile app](https://affiliate-program.amazon.com/help/node/topic/GFP8AD2UDZDQTJPP)
- Walmart Creator: 1,000 followers per terms, US residence and bank account; Walmart Affiliate Program states no follower minimum and is built for website publishers — [CreatorFlow, updated 2026-08-21](https://creatorflow.so/blog/walmart-creator-program/)
- Weee! via FlexOffers: publisher applies through FlexOffers and waits for approval — [FlexOffers, Weee! listing, 2026-04-29](https://www.flexoffers.com/affiliate-programs/sayweee-com-affiliate-program/)

### Inferences
- Affiliate networks (Impact, FlexOffers) generally ask for a web property at sign-up; Pantry would likely need at least a simple product website to apply, though this is general practice and was not confirmed for each programme. One caution relevant to the brief's "family-friendly content" approval criterion: the placeholder bundle id sits under the SkasieHI name, and the applying business entity and site should be chosen with that criterion in mind.
- "No analytics beyond Apple's" is compatible with these programmes: conversion tracking happens on the retailer and network side, and the developer sees aggregate reports in the network dashboard without collecting anything in-app.

### Gaps
- Minimum traffic thresholds for Instacart/Impact, Walmart Affiliate, FlexOffers: not found.
- Whether any programme forbids affiliate links inside a game or requires disclosure wording in-app: not found beyond Instacart's CTA and copy rules.
