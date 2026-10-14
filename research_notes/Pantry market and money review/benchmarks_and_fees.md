# Benchmarks and platform fees for a freemium iOS game with a small subscription and one-time purchases (as of 2026-10-08)

Reading notes for the writer:
- "RC 2026" = RevenueCat, State of Subscription Apps 2026 (published March 2026; 115,000+ apps, $16B+ revenue, 1B+ transactions; metric period is calendar 2025; iOS + Android + web, global unless stated). The web report page is long and was read through a summarising fetch; the page itself contains a few internally conflicting figures, flagged below.
- "GA 2026" = GameAnalytics, Mobile and PC Game Benchmarks 2026 (published Jan 2026; 16,262 live mobile games with at least 1k MAU, iOS + Android, Jan 1 to Dec 31 2025).
- Nothing below is interpolated. Arithmetic I did myself is confined to the Inferences sections and labelled.
- Several secondary blog sources do not name a primary source or year for their numbers. Those are marked "weak".

## 1. Retention: Day 1 / Day 7 / Day 30 for games and for education and food and drink apps

### Takeaway
The median mobile game in North America keeps about 23% of players on Day 1, 5% on Day 7 and 1.2% on Day 30 (GameAnalytics, 2025 data, iOS and Android combined); the top 10% reach about 37% / 13% / 5%. Genre-level and iOS-only splits, and any D7/D30 figure for education or food and drink apps, were not found in a primary source; the only category figure for food and drink is a D1 of 13% (Adjust, published 2024).

### Cited Findings
- GA 2026, mobile games, North America, 2025 yearly averages: D1 P50 23.28%, P90 36.90%, P99 50.89%; D7 P50 4.97%, P90 12.58%, P99 24.78%; D30 P50 1.18%, P90 4.78%, P99 13.26%. Regional tables give only P50/P90/P99 (no quartiles). Retention = share of players returning on Day N after first play. — [GameAnalytics 2026 benchmarks PDF (InvestGame mirror)](https://investgame.net/wp-content/uploads/2026/01/2026-01-27-2026-mobile-pc-benchmarks_compressed.pdf)
- GA 2026, mobile games, global, 2025: D1 bottom quartile (P25) about 12.5 to 13.4%, median about 22%, top quartile (P75) just above 30%, top 10% about 40%; D7 P25 1.67 to 1.94%, median just under 4%, P75 6 to 7%, P90 11 to 12%; D30 P25 under 0.5%, median 0.68 to 0.79%, P75 1.6 to 1.8%, P99 13 to 15%. No genre split and no iOS vs Android split in this edition. — [GameAnalytics 2026 benchmarks PDF](https://investgame.net/wp-content/uploads/2026/01/2026-01-27-2026-mobile-pc-benchmarks_compressed.pdf)
- GA 2026 engagement, North America medians: playtime 14.45 min/day, session length 3.64 min, 4.23 sessions/day (P90: 45.84 min, 8.50 min, 7.59). — [GameAnalytics 2026 benchmarks PDF](https://investgame.net/wp-content/uploads/2026/01/2026-01-27-2026-mobile-pc-benchmarks_compressed.pdf)
- Genre retention attributed to Mistplay (year not stated; Mistplay is a rewarded-play Android audience, so not iOS and likely skewed high): Puzzle D1 31.85%, D7 12.18%, D30 5.35%; Match D1 32.65%, D7 13.98%, D30 7.15%; Simulation D1 30.10%, D7 8.71%, D30 2.96%; Hyper-casual D1 29.31%, D7 5.90%, D30 1.38%. No word, trivia or "casual" row. Weak (secondary, undated). — [Segwise, Mobile Game User Retention 2026](https://segwise.ai/blog/mobile-gaming-app-user-retention-strategies.md)
- Adjust all-vertical medians (article published Apr 16 2024; underlying data year not stated; OLDER THAN 2 YEARS): iOS D1 27%, D7 14%, D14 11%, D30 8%; all platforms 26% / 13% / 10% / 7%; North America all verticals D1 23%, D7 10%, D14 7%, D30 5%. — [Adjust, What makes a good retention rate](https://www.adjust.com/blog/what-makes-a-good-retention-rate/)
- Adjust D1 by vertical (same 2024 article; OLDER THAN 2 YEARS): Games 29% (North America 26%), Health and fitness 27% (North America 21%), Food and drink 13% (about 10 to 11% across regions). Education is not broken out. Only D1 is given by vertical. — [Adjust, What makes a good retention rate](https://www.adjust.com/blog/what-makes-a-good-retention-rate/)
- Unsourced blog averages for games: D1 about 28 to 30%, D7 10 to 13%, D30 3 to 5%. No primary source or year named; these are far above the GameAnalytics medians and should not be used as medians. Weak. — [Panto, mobile app retention statistics](https://www.getpanto.ai/blog/mobile-app-retention-statistics)

### Inferences
- The gap between GameAnalytics (median D30 about 1%) and Adjust/blog figures (D30 5 to 8%) is methodological, not a contradiction to average away: GameAnalytics counts every live game with 1k+ MAU including a long tail, while MMP datasets (Adjust, AppsFlyer) skew to apps that buy marketing and are measured by install cohort. For a solo developer with no paid marketing, the GameAnalytics distribution is the more conservative planning base; the Adjust iOS figures are closer to "a funded, competently run app".
- A reasonable planning band for Pantry from cited data only: median case D1 23% / D7 5% / D30 1.2% (GA North America P50); strong case D1 37% / D7 12.6% / D30 4.8% (GA North America P90). Top-quartile for North America is not published; the global P75 (D1 just above 30%, D7 6 to 7%, D30 1.6 to 1.8%) is the nearest cited figure.

### Gaps
- D1/D7/D30 for casual, puzzle, word and trivia genres on iOS in the US from a primary 2025 or 2026 source: not found. GameAnalytics' 2026 edition dropped the genre split; AppsFlyer and Liftoff genre reports were not reached.
- Education app D1/D7/D30: not found in any primary source reached.
- Food and drink D7 and D30: not found (D1 only, and that is pre-2024 data).
- North America top-quartile and bottom-quartile game retention: not published in GA 2026 regional tables.

## 2. Free-to-paid conversion: payer conversion in games; install-to-paid and trial-to-paid for subscription apps

### Takeaway
For subscription apps the median download-to-paid conversion within 35 days is 2.0% overall, 1.4% for low-priced apps and 1.0% for gaming apps, with freemium apps at about 2.1% versus 10.7% for hard paywalls (RevenueCat 2026). In free-to-play games broadly, "less than 5%" of players ever pay and 0.5 to 1% is described as acceptable for casual genres, but those two game figures are secondary and loosely sourced.

### Cited Findings
- RC 2026 download-to-paid at Day 35, median (top quartile): all apps 2.0%; Health and Fitness 2.9% (above 6.2%); Business 2.6% (above 5.0%); Shopping 1.3%; Gaming 1.0% (above 2.3%). — [RevenueCat, State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 download-to-paid by price tier, median (top quartile): low-priced 1.4% (above 3.7%); mid-priced 2.0% (above 4.4%); high-priced 2.8% (above 6.1%; top 10% 13.5%). — [RevenueCat, State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 by access model: freemium median download-to-paid 2.1% vs 10.7% for hard paywalls (the report's own summary rounds this to "2% vs 11%"). — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps); [RevenueCat SOSA 26 insights](https://revenuecat.com/sosa-26-insights/)
- RC 2026 trial-to-paid, median (top quartile): Gaming 25.0% (above 39.8%); Health and Fitness 37.7% (above 51.4%); Travel 43.5% (above 62.4%); Photo and Video 22.2% (above 33.1%). By trial length: 4 days or fewer 25.5%; 5 to 9 days 37.4%; 17 to 32 days 42.5%. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 Education: download-to-trial (D30) median 6.5%; only 28.5% of conversions happen on Day 0, the lowest of any category; 50.3% of trials are 5 to 9 days. Low-priced apps: download-to-trial median 4.4%. Education download-to-paid and trial-to-paid were not in the portion of the report read. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 trial cancellations on Day 0: 3-day trials 55.4%, 7-day 39.8%, 14-day 35.7%, 30-day 31.1%. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- Adapty, State of In-App Subscriptions 2026 (published Mar 5 2026; 16,000 apps, $3B subscription revenue; global): install-to-trial 10.9%; trial-to-paid 25.6%; Health and Fitness trial-to-paid 35.0%; Entertainment 19.1%. — [Adapty 2026](https://adapty.io/state-of-in-app-subscriptions/)
- AppsFlyer, State of App Monetization 2026 (via a June 25 2026 summary; revenue base Jan 2025 to Mar 2026; global, cross-platform; MMP-measured apps): install-to-first-purchase within 30 days: non-gaming apps 9.84% (4.64% repeat); casino games 4.95% (3.01% repeat); North America first-purchase conversion 11.14%. No casual-game or iOS-only payer conversion given. These rates are far above RevenueCat's and reflect a different population (apps with attributed purchase events, not all subscription apps). — [GameDev Reports summary of AppsFlyer 2026](https://gamedevreports.substack.com/p/appsflyer-app-monetization-in-2026)
- Games payer conversion: "less than 5% of mobile gamers ever open their digital wallets" attributed to an AppsFlyer 2024 report (OLDER THAN 2 YEARS by data), and "most casual genres consider 0.5 to 1% acceptable" attributed to Segwise and industry data with no year. Weak. — [Juego Studio, ARPDAU benchmarks by genre](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre)
- TechCrunch's report of RC 2026 gives "download monetization" medians of 2.4% for AI apps vs 2.0% for non-AI apps, consistent with the 2.0% overall median. It also quotes "trial-to-paid" 8.5% vs 5.6%, which conflicts with the 25%+ trial-to-paid medians above and is probably a different metric (likely download-to-trial); treat as unverified. — [TechCrunch, Mar 10 2026](https://techcrunch.com/2026/03/10/ai-powered-apps-struggle-with-long-term-retention-new-report-shows)

### Inferences
- The most applicable single number for Pantry's $3.99/month subscription is RC 2026's low-priced tier: 1.4% median download-to-paid by Day 35, above 3.7% for the top quartile. The gaming-category median (1.0%, top quartile above 2.3%) is the pessimistic cross-check. Both are for apps whose primary monetisation is subscription; Pantry's subscription is a utility add-on to a game, which the benchmarks do not model.
- RevenueCat's "low-priced" tier is defined relative to its dataset (the common monthly price is $10; the Education monthly median is $9.99), so $3.99 sits at the low end of the low tier. No benchmark specifically for monthly plans under $5 was found.

### Gaps
- Download-to-paid and trial-to-paid for Education specifically: not found in the portion of RC 2026 read (the report has per-category pages that were not fetched).
- Food and Drink: RevenueCat does not report it as a category. Not found elsewhere.
- Conversion specifically for monthly plans priced under $5: not found.
- Payer conversion (share of installs or MAU who ever pay) for casual / puzzle / word games on iOS from a primary 2025 or 2026 source: not found.
- Bottom-quartile conversion figures: not found.

## 3. Subscription churn and lifetime: monthly-plan retention, realised LTV, plan mix

### Takeaway
Monthly plans retain poorly: RevenueCat 2026 puts median 12-month retention of monthly subscribers at 10.8% for low-priced apps (6.1% for high-priced; about 9.5% for non-AI apps overall), and the median low-priced app realises $6.67 per payer in the first month and $10.69 after a year. Retention at 1, 3 and 6 months was not found.

### Cited Findings
- RC 2026 retention after one year by price tier (medians): annual plans 36% for low-priced apps vs 23% for high-priced; monthly plans 10.8% (low-priced) vs 6.1% (high-priced); weekly plans 1.3% vs 1.0%. The source sentence reads "Median retained subscribers after 1 year: 36% low-priced vs 23% high-priced" followed by the monthly and weekly figures, so the 36%/23% pair is read here as the annual-plan figure; that reading is consistent with the 28 to 31% annual figures below but should be checked against the report chart. — [RevenueCat SOSA 26 insights](https://revenuecat.com/sosa-26-insights/)
- RC 2026 (via TechCrunch) 12-month retention, non-AI apps vs AI apps: annual 30.7% vs 21.1%; monthly 9.5% vs 6.1%; weekly 1.7% vs 2.5%. — [TechCrunch, Mar 10 2026](https://techcrunch.com/2026/03/10/ai-powered-apps-struggle-with-long-term-retention-new-report-shows)
- RC 2026 one-year retention by access model: hard paywall 27%, freemium 28%. — [RevenueCat SOSA 26 insights](https://revenuecat.com/sosa-26-insights/)
- RC 2026 annual plans: first-year retention fell from 31% to 28% year over year; 24 to 47% of annual subscribers stay after first renewal depending on category and price; 35% of all annual cancellations happen in month 1. — [PPC Land on RC 2026](https://ppc.land/95-of-annual-app-subscribers-who-cancel-never-return-revenuecat-finds/)
- RC 2026 reactivation: 20% of churned monthly subscribers come back within a year (6% to 36% by category; 18 to 24% by region); annual reactivation is 5% overall. — [PPC Land on RC 2026](https://ppc.land/95-of-annual-app-subscribers-who-cancel-never-return-revenuecat-finds/)
- RC 2026 realised LTV per payer by price tier (medians): low-priced $6.67 at 1 month, $10.69 at 1 year; mid-priced $15.78 at 1 month, $28.75 at 1 year (the insights page says $26.07 for mid-priced at 1 year; conflict within RevenueCat's own pages); high-priced $35.89 at 1 month (top quartile above $56), $62.19 at 1 year (top quartile above $109.64). — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps); [RevenueCat SOSA 26 insights](https://revenuecat.com/sosa-26-insights/)
- RC 2026 realised LTV per payer by category (medians): Gaming $8.41 at 1 month, $11.22 at 1 year; Education $22.82 at 1 year; Productivity $24.95 at 1 year; Health and Fitness $24.23 at 1 month (top quartile above $39.00), $35.64 at 1 year; Business $35.48 at 1 year (top quartile above $69.19). All apps, global, 1 year: $23 median (top quartile above $44). North America 1 year: $26.07 in the geography section vs $32 by developer HQ (two different cuts). — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 refund rate: median 3.5% for non-AI apps (upper bound 12.5%); 4.2% for AI apps. — [TechCrunch, Mar 10 2026](https://techcrunch.com/2026/03/10/ai-powered-apps-struggle-with-long-term-retention-new-report-shows)
- RC 2026 plan mix: overall 42% monthly and 34% yearly (as stated in the pricing section; remainder not stated); Gaming 82% weekly (labelled "weekly + monthly" elsewhere on the same page); Productivity 77% yearly; Education sits in a 59 to 66% annual band with Travel and Shopping. Median prices: Education $9.99 monthly, $44.99 yearly; common monthly price $10, common weekly $5. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 monetisation mix by share of apps: 63.5% subscriptions only; 23.2% subscriptions plus lifetime; 10.7% subscriptions plus consumables; 2.5% all three. Gaming: 40.5% subscriptions only, 27.5% plus consumables, 9.6% all three. About one in four apps offers a lifetime plan. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- Adapty 2026 (global): retention at Day 380 by plan started from a trial: annual 19.9%, monthly 14.2%, weekly 5.5%; first-renewal retention ranges from 58.1% (Utilities) to 30.3% (Health and Fitness); weekly plans are 55.5 to 56% of app subscription revenue; "monthly plans underperform both weekly and annual at every price tier"; 2025 global median prices weekly $7.48, monthly $12.99, annual $38.42; median app revenue $492/month; 59.3% of subscription apps earn under $1,000 in total. — [Adapty 2026](https://adapty.io/state-of-in-app-subscriptions/)
- Involuntary billing failures are 14% of cancellations on the App Store (31% on Google Play). — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)

### Inferences
- For a $3.99 monthly plan, the directly cited planning figures are: about 10 to 11% of monthly subscribers still subscribed at 12 months (RC low-priced median 10.8%; Adapty's monthly-from-trial 14.2% at Day 380 is the optimistic cross-check), and gross realised LTV per payer on the order of $10 to $11 in year one (RC low-priced $10.69; gaming $11.22). Those LTV figures are medians across apps with mixed prices and plan types, not specific to $3.99, and are before Apple's commission as far as the report states (RevenueCat reports revenue; net-of-commission treatment was not confirmed).
- Median first-month realised LTV of $6.67 for low-priced apps against $10.69 at one year implies most realised value arrives in the first payment or two; this is consistent with the 10.8% 12-month monthly retention.

### Gaps
- Monthly-plan retention at 1, 3 and 6 months (renewal curve): not found in the sources reached. RevenueCat publishes retention by renewal period in its charts, but the figures were not in the text retrieved.
- Realised LTV specifically for monthly plans under $5: not found.
- Top and bottom quartiles for monthly retention: not found.
- Whether RevenueCat's LTV is gross or net of store commission: not confirmed.

## 4. Revenue per install / download for subscription apps; ARPDAU for casual games without ads

### Takeaway
Median revenue per install for subscription apps is tiny: $0.23 at Day 14 and $0.34 at Day 60 across all apps, $0.08 and $0.11 for low-priced apps, $0.08 and $0.14 for gaming apps, and $0.30 at Day 14 for education (RevenueCat 2026). No benchmark for ARPDAU of ad-free casual games was found; the only cited casual ARPDAU range ($0.03 to $0.10) is blended with ads.

### Cited Findings
- RC 2026 revenue per install, medians (D14 / D60): all categories $0.23 / $0.34; Gaming $0.08 / $0.14; Education $0.30 / not given; Business $0.31 / $0.50; Health and Fitness $0.48 / $0.66. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- RC 2026 RPI by price tier (D14 / D60): low-priced $0.08 / $0.11; high-priced $0.61 / $0.94. By access: hard paywall $2.32 at D14 (top quartile above $4.50) and $3.09 at D60 (top quartile above $5.50); freemium $0.27 at D14. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps); [RevenueCat SOSA 26 insights](https://revenuecat.com/sosa-26-insights/)
- RC 2026 RPI, North America: $0.38 at D14, $0.55 at D60 (top quartile above $1.39; P90 $3.19). — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- AppsFlyer 2026 (global, cross-platform, MMP-measured apps): D90 IAP ARPU casual games $1.34; non-gaming apps $2.32 (North America and Europe $2.79); D90 ad ARPU casual $0.55; D90 IAP ARPPU casual $7.26, non-gaming $10.85. Revenue timing: 60% of D60 IAP revenue arrives by Day 7; 52% of D60 subscription revenue by Day 7 (28% on Day 1). — [GameDev Reports summary of AppsFlyer 2026](https://gamedevreports.substack.com/p/appsflyer-app-monetization-in-2026)
- Casual / puzzle ARPDAU $0.03 to $0.10, blended IAP plus ads, described as 2024 to 2025 reference ranges "drawn from" AppsFlyer, GameAnalytics, Liftoff and Appodeal without a specific citation. Weak. — [Juego Studio, ARPDAU benchmarks by genre](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre)
- In mixed-model games, advertising was 56% of revenue in early 2026, IAP about 35%, subscriptions 7% (up from 4% in Jan 2025). — [GameDev Reports summary of AppsFlyer 2026](https://gamedevreports.substack.com/p/appsflyer-app-monetization-in-2026)

### Inferences
- Since ads are 56% of revenue in mixed-model games and Pantry has none, a blended casual ARPDAU or ARPU benchmark overstates what an ad-free casual game should expect; the IAP-only casual D90 ARPU ($1.34 global, MMP-measured) and RevenueCat's gaming RPI ($0.14 at D60) bracket the plausible range from above and below. The two differ by an order of magnitude because of sample differences (marketing-funded games with consumable economies vs all subscription-SDK apps).
- For Pantry's model, the cited low end is about $0.11 to $0.14 gross per install at D60 (RC low-priced and gaming medians) and the cited North America median for subscription apps is $0.55.

### Gaps
- ARPDAU for casual, puzzle or word games without ads (IAP-only), iOS US: not found.
- Revenue per install at one year: not published by RevenueCat (D14 and D60 only).
- RPI for Food and Drink: not found. Education D60 RPI: not in the text retrieved.

## 5. One-time (non-consumable) content-pack conversion rates

### Takeaway
No benchmark was found for conversion to non-consumable "unlock" or content-pack purchases in premium-content or educational games. The nearest adjacent data are RevenueCat's share of apps offering lifetime purchases and AppsFlyer's first-purchase rates, neither of which measures what Pantry's $9.99 cuisine tracks would do.

### Cited Findings
- 23.2% of subscription apps pair subscriptions with a lifetime (one-time) product and about one in four apps offers a lifetime plan; about 10% of apps run true hybrid models, roughly four times more common in gaming. These are shares of apps, not conversion rates. — [RevenueCat 2026](https://www.revenuecat.com/state-of-subscription-apps)
- Install-to-first-purchase within 30 days (any IAP, MMP-measured apps, global): non-gaming 9.84%, casino games 4.95%, North America 11.14%; D90 IAP ARPPU for casual games $7.26. Not specific to non-consumables. — [GameDev Reports summary of AppsFlyer 2026](https://gamedevreports.substack.com/p/appsflyer-app-monetization-in-2026)

### Inferences
- In the absence of a benchmark, the defensible modelling choice is to treat track-purchase conversion as an unknown with a range anchored on cited payer-conversion figures (0.5 to 1% "acceptable" for casual per a weak source; under 5% of gamers ever pay; 1.0 to 2.1% download-to-paid for gaming and freemium subscription apps) and to state plainly that it is an assumption to be tested, not a benchmark.

### Gaps
- Non-consumable / content-pack / "unlock full game" conversion rate for edu or premium-content games: not found.
- Attach rate of one-time purchases among existing subscribers, and repeat purchase rate across multiple packs: not found.

## 6. Apple's commission terms as of October 2026

### Takeaway
A solo US developer earning under $1M a year pays the $99 annual Apple Developer Program fee and, once enrolled in the App Store Small Business Program (enrolment is required), 15% commission on in-app purchases and subscriptions sold through Apple's system; without enrolment the standard rate is 30%. In the US, apps may link out to web checkout and Apple is currently collecting no commission on those purchases under the Epic v. Apple contempt order, but that is under Supreme Court review (cert granted June 30 2026, ruling expected by June 2027) and the Ninth Circuit has already said Apple may be allowed a cost-based fee to be set on remand.

### Cited Findings
- Apple Developer Program: 99 USD per membership year; fee waivers only for nonprofits, educational institutions and government entities. — [Apple, Compare memberships](https://developer.apple.com/support/compare-memberships/)
- Small Business Program: 15% commission on paid apps and Apple In-App Purchases. Eligibility: proceeds (sales net of Apple's commission and certain taxes and adjustments) of no more than 1 million USD across the 12 fiscal months of the previous calendar year, and also no more than 1 million USD in the current year; new developers qualify. Must enrol: be the Account Holder, accept the latest Paid Apps agreement, and declare all Associated Developer Accounts (over 50% ownership or ultimate decision authority), whose proceeds count toward the threshold. If proceeds pass 1 million USD in the current year, the standard commission applies to future sales for the rest of the year; a developer who falls back below can requalify the following year. The reduced rate takes effect 15 days after the end of the fiscal month in which enrolment is approved. — [Apple, App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- Standard commission is 30%, reduced to 15% under the Small Business Program (launched 2020) for developers earning under $1 million per year. Apple (via an Apple-funded study) says developers paid no commission on about 90% of 2024 US App Store ecosystem billings and sales. — [TechCrunch, May 29 2025](https://techcrunch.com/?p=3013090)
- Auto-renewing subscriptions in their second year are charged the reduced 15% rate (stated in the EU single-terms context: Apple In-App Purchase 26%, dropping to 15% for small businesses and second-year auto-renewing subscriptions). — [Phiture, Apple's new App Store terms 2026](https://phiture.com/blog/apple-new-app-store-terms-2026/)
- Apple's Small Business Program page also mentions a further reduced 10% commission for developers on EU alternative terms and for subscriptions after their first year; the page wording, as retrieved, is ambiguous about scope. Do not assume a 10% rate applies to a US developer's US sales. — [Apple, App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- Epic v. Apple, US: in April 2025 Judge Yvonne Gonzalez Rogers held Apple in contempt and ordered it to stop charging any commission on purchases made through external links (Apple had been charging 27% on purchases within seven days of a link click). In December 2025 the Ninth Circuit upheld the contempt finding but said barring all commission "went too far": Apple may charge a fee based on costs "genuinely and reasonably necessary" for coordinating external-link purchases, with the rate to be set on remand. In May 2026 Justice Kagan denied Apple's emergency stay request. On June 30 2026 the Supreme Court granted cert (No. 25-1311), limited to the contempt question and excluding the universal-injunction question; argument is in the term beginning October 2026 with a ruling expected by June 2027. Apple "has not collected commission on external-link payments for nearly a year". — [The Next Web](https://thenextweb.com/news/supreme-court-apple-epic-contempt-app-store-commission); [iClarified, Jul 18 2026](https://www.iclarified.com/101339/supreme-court-to-hear-apples-appeal-of-app-store-contempt-ruling)
- EU (DMA) terms effective October 1 2026, a single set of business terms: Apple In-App Purchase 26% (15% for small businesses, mini apps, video partner programme and second-year auto-renewing subscriptions); alternative payment processing 20% (10% for small developers and eligible programmes); external link-outs 15% (10% for small developers); a 5% Core Technology Commission on digital transactions for apps distributed via alternative marketplaces or the web. The per-install Core Technology Fee, Initial Acquisition Fee and Store Services Fee are removed. Kids-category apps and apps for under-13s cannot include external purchase links. — [Phiture, Apple's new App Store terms 2026](https://phiture.com/blog/apple-new-app-store-terms-2026/); Apple's own announcement: [Apple Newsroom, Aug 2026](https://apple.com/newsroom/2026/08/apple-announces-changes-for-apps-in-the-european-union) (not fetched directly; details above are from Phiture)

### Inferences
- What a solo US developer under $1M pays, stated exactly from the cited terms: (1) $99 per year membership; (2) 15% of the customer price (after any sales tax Apple remits) on every In-App Purchase and subscription payment sold through Apple, from year one, provided the developer has enrolled in the Small Business Program and it has taken effect; 30% until then or if not enrolled; (3) the 15% second-year subscription rate gives no further saving to a Small Business Program member in the US, because they are already at 15%; (4) nothing to Apple, as of October 2026, on purchases completed on the developer's own website via an in-app link in the US storefront, though the developer then pays their own payment processor and this zero rate is legally unsettled.
- Arithmetic (mine): at 15%, a $3.99 monthly subscription nets about $3.39 per payment and a $9.99 track nets about $8.49, before any sales-tax effects and income tax. At 30% the figures are about $2.79 and $6.99.
- Because a new developer is not in the Small Business Program until enrolment is approved and the fiscal-month lag passes, enrolling before the first sale matters; early sales would otherwise be at 30%.
- A cooking game that might be classed in the Kids category should note that the EU terms bar external purchase links for Kids-category apps; whether a similar restriction applies to US link-outs was not checked.

### Gaps
- Apple's primary documentation for the standard 30% rate and the year-two 15% subscription rate was not fetched directly; both are supported here through TechCrunch and Phiture. Apple's auto-renewable subscriptions page should be cited by the writer if a primary source is required.
- The exact text of Apple's current US App Review Guideline on external purchase links (entitlement requirements, any restrictions for Kids-category apps) was not retrieved.
- The remand schedule and any proposed cost-based US link-out fee: not found.
- Whether the Small Business Program page's 10% mention applies outside the EU: unresolved.
- Sales-tax handling and state-level detail: out of scope, not researched.

## 7. Cost to acquire a user: iOS US CPI and organic share

### Takeaway
On Apple Ads search results in the US in 2025, the median cost per install was $4.63 for games and $2.91 for education apps (AppTweak, about 2,800 US advertisers); a secondary source puts US iOS CPI across channels at $0.90 to $2.50 for casual games, $2.00 to $6.00 for education and $1.80 to $4.50 for food and delivery. Against median revenue per install of $0.08 to $0.55, paid acquisition does not pay back at median performance. No reliable figure for the organic share of installs for indie apps was found.

### Cited Findings
- AppTweak Apple Ads benchmarks, US, Jan to Dec 2025, search results placement, about 2,800 US advertisers, medians across monthly app and campaign rows (not spend-weighted): Games CPT $2.03, CPI $4.63, tap-to-install 61.8%, TTR 9.3%; Education CPT $1.52, CPI $2.91, tap-to-install 56.4%, TTR 8.3%; Health and Fitness CPT $1.68, CPI $3.77, tap-to-install 50.3%, TTR 7.5%. Food and Drink not reported. — [AppTweak, Apple Ads benchmarks](https://www.apptweak.com/en/aso-blog/apple-ads-benchmarks?format=md)
- AppTweak Campaign Manager dataset, US, 2025 (nearly 3,500 apps, 50,000 campaigns, $1B spend, 38 countries; all categories): search results CPT $1.91, CPI $4.06, conversion 55%, TTR 6.60%. — [AppTweak, Apple Ads benchmarks](https://www.apptweak.com/en/aso-blog/apple-ads-benchmarks?format=md)
- US iOS CPI ranges described as 25th to 75th percentile bands, 2025 to 2026, attributed collectively to "published MMP-based industry reports (AppsFlyer, Adjust, Sensor Tower)" without per-figure citation: casual games $0.90 to $2.50; Education and EdTech $2.00 to $6.00; Food and Delivery $1.80 to $4.50. The post says Apple Search Ads CPIs are typically higher than broad Meta campaigns with better downstream quality, and gives no numeric Meta or TikTok CPI. Weak (secondary, agency blog, Sep 8 2026). — [SEM Nexus, CPI benchmarks 2026](https://semnexus.com/cpi-benchmarks-app-category-platform-2026/)
- AppsFlyer 2026 share of revenue (not installs) coming from paid installs: gaming IAP 59%; casual games 61% of total revenue; non-gaming apps 30% (North America 31%). — [GameDev Reports summary of AppsFlyer 2026](https://gamedevreports.substack.com/p/appsflyer-app-monetization-in-2026)

### Inferences
- Comparing cited medians: Apple Ads CPI of $2.91 (education) to $4.63 (games) against RevenueCat D60 revenue per install of $0.11 (low-priced), $0.14 (gaming) or $0.55 (North America, all apps) means median paid installs return roughly 3 to 20 cents on the dollar within 60 days before Apple's commission. Paid acquisition would need top-quartile-or-better monetisation (North America RPI top quartile above $1.39; P90 $3.19) to approach break-even. The unit-economics model should treat organic and owned channels as the base case.
- For non-gaming apps roughly 70% of revenue comes from organic installs (AppsFlyer, MMP-measured), which suggests organic-led growth is normal for the subscription/utility side of Pantry's profile, less so for casual games (39% organic revenue share).

### Gaps
- Paid social (Meta, TikTok) CPI for casual games and education or food apps on iOS in the US from a primary source: not found.
- Apple Ads CPI for Food and Drink: not found. Apple Ads CPI for casual / puzzle / word sub-genres: not found (Games category only).
- Share of installs that indie or solo-developer apps get organically: not found. (An eMarketer KPI page on paid vs organic install share returned a 404.)

## 8. Cost per round of a short LLM call (order of magnitude)

### Takeaway
At October 2026 list prices, a call of a few hundred tokens in and out costs on the order of two hundredths of a cent on the cheapest small models and a few tenths of a cent on mid-tier models, so the judge line is a negligible cost per round unless rounds per user are very high.

### Cited Findings
- Anthropic list prices per million tokens (input / output): Claude Haiku 5.5 $0.10 / $0.50 for prompts up to 100K tokens; Claude Sonnet 5.5 $2 / $10; Claude Opus 5.5 $4 / $20; Claude Haiku 4.5 $1 / $5. Batch API is 50% off; cache reads are 0.1x input or lower. — [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- OpenAI list prices per million tokens (input / output), standard short-context: gpt-6-luna $0.10 / $0.50; gpt-6.1-sol $2.00 / $10.00; gpt-6-astra $10.00 / $50.00. — [OpenAI pricing](https://developers.openai.com/api/docs/pricing)
- Google Gemini paid-tier prices per million tokens (input / output): Gemini 3.1 Flash-Lite $0.25 / $1.50; Gemini 3.5 Flash-Lite $0.30 / $2.50; Gemini 3.8 Flash $0.75 / $3.75 through Dec 31 2026, then $1.50 / $7.50 from Jan 1 2027; Gemini 3.1 Pro Preview $2.00 / $12.00 for prompts up to 200k tokens. — [Google Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing)

### Inferences
- Arithmetic (mine), for an illustrative 300 input tokens and 300 output tokens per round, no caching or batch discount:
  - Small tier: Claude Haiku 5.5 or gpt-6-luna about $0.00018 per round (roughly $0.18 per 1,000 rounds); Gemini 3.1 Flash-Lite about $0.0005; Gemini 3.8 Flash about $0.0014 at 2026 prices.
  - Mid tier: Claude Sonnet 5.5 or gpt-6.1-sol about $0.0036 per round (roughly $3.60 per 1,000 rounds); Gemini 3.1 Pro Preview about $0.0042.
- Order of magnitude: $0.0001 to $0.001 per round on small models and $0.003 to $0.005 on mid-tier models. A free user playing 100 rounds a month would cost about 2 cents on a small model and about 36 cents on a mid-tier one; the latter is material against a median revenue per install of $0.08 to $0.14, the former is not.
- A system prompt carrying the cuisine grammar would raise input tokens well above "a few hundred"; input is the cheap side, and prompt caching reduces it further, but the model should size the real prompt before fixing a number.

### Gaps
- Proxy hosting cost (the server that holds the API key) was not researched.
- Prices are list prices on the day of retrieval (2026-10-08); Google has already announced a Flash price rise for Jan 1 2027.
