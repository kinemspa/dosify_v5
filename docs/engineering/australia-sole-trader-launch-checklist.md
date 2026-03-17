# Australia Sole Trader Launch Checklist

Date: 2026-03-17

This document is a practical launch checklist for publishing and monetizing Skedux in Australia as a sole trader.

It is not legal, tax, accounting, insurance, or financial advice. Use it as an operational guide and confirm anything important with an Australian accountant, lawyer, insurance broker, or the relevant government agency.

## Goal

Launch Skedux in a way that:

1. protects your privacy as much as possible
2. keeps payments and tax setup clean
3. supports Google Play billing and merchant setup
4. avoids rushing into public exposure of your home address

## Recommended Order

If you want the cleanest path, do the steps in this order:

1. Decide whether to launch free first or with paid Pro from day one.
2. Decide whether you are comfortable operating as a sole trader initially.
3. Secure a legitimate non-home business address solution if you do not want to use your home address.
4. Check the `Skedux` name before committing to it commercially.
5. Apply for an ABN as a sole trader.
6. Register a business name if you will trade publicly as `Skedux`.
7. Set up a domain, support email, and minimum website.
8. Open a separate business banking arrangement if possible.
9. Set up bookkeeping from day one.
10. Complete your Google payments profile and Play billing setup.

If privacy is the priority and monetization can wait, the safer path is:

1. launch the app free first
2. postpone paid Pro until business/address setup is ready

## Phase 1: Decide Your Structure

As a sole trader in Australia, you are the business legally. You do not form a separate legal entity like a company.

This is usually the simplest and fastest path for a solo app founder, but it also means:

1. your business income generally flows into your personal tax position
2. your liability position is not separated from you the way it would be in a company
3. some legal and payment records may still be tied to your personal identity

## Phase 2: Solve The Address Problem First

If you do not want to use your home address, do not enter a fake one.

Your practical Australian options are:

1. virtual office with a real street address
2. coworking membership with address rights
3. accountant or business service address, if they explicitly permit it
4. later, a company registered office or principal place of business

Before paying for any address solution, verify all of these:

1. it is a real street address, not only a PO Box
2. you are allowed to use it for business registration and correspondence
3. it can receive mail and verification if needed
4. it is acceptable for merchant and payment onboarding
5. you understand whether it may appear publicly anywhere

Do not assume a PO Box alone will satisfy every merchant or verification requirement.

## Phase 3: Check The Brand Name

Before you spend money on the brand, check whether `Skedux` is usable.

At minimum, do these searches:

1. ASIC business name search
2. IP Australia trade mark search
3. domain name search
4. Google Play and broader web search for obvious conflicts

Do this before registering the business name, domain, merchant identity, or public site.

## Phase 4: Get An ABN

If you are operating as a business, the ABN is usually the first formal step.

Practical notes:

1. apply through the official Australian Business Register
2. use your real legal personal details
3. choose the business structure as sole trader
4. keep the ABN confirmation records
5. avoid paid middleman registration websites unless you specifically want their service

## Phase 5: Register A Business Name

If you want to trade publicly as `Skedux`, you will usually want to register `Skedux` as a business name.

Practical rule:

1. if you trade only under your exact personal legal name, you may not need a separate business name
2. if you trade publicly as `Skedux`, you will usually want the business name registered

## Phase 6: Banking And Record Separation

Do this early even as a sole trader:

1. open a separate transaction account if possible
2. keep app revenue and app expenses separate from personal spending
3. use one consistent account/card for business-related costs

Typical costs to track:

1. Google Play fees
2. hosting and domain costs
3. software subscriptions
4. ads and creative services
5. legal/accounting costs
6. contractor spend

## Phase 7: Tax And GST Basics

You need an accountant or the ATO for definitive advice, but operationally:

1. business income is usually reported through your personal tax return as a sole trader
2. keep clean records from day one
3. you may need GST registration once turnover reaches the relevant threshold
4. do not register for GST casually without understanding the implications

If your turnover is still small, you may not need GST immediately, but good bookkeeping is still mandatory.

## Phase 8: Minimum Public Presence

Before turning on paid monetization, set up:

1. a domain
2. a support email
3. a basic website or landing page
4. a Privacy Policy page
5. a Terms page
6. a Support page

You already have a repo launch kit for this in [docs/marketing/website-launch-kit.md](docs/marketing/website-launch-kit.md).

## Phase 9: Google Payments And Merchant Setup

Before you complete Google payments setup, have these ready:

1. real legal personal identity
2. ABN
3. registered business name if using one
4. address solution you are entitled to use
5. bank account details
6. support email
7. website, privacy, and support pages

Use your real legal identity for tax and payout details.

If Google allows a public merchant display separate from the legal payee details, use the brand name `Skedux` only if it is truthful and not misleading.

Do not:

1. invent a fake business name
2. use an address you do not control or cannot lawfully use
3. misrepresent a non-existent company entity

## Phase 10: Google Play Billing Setup

After the payments profile is ready:

1. keep the app listing free if Pro is an in-app purchase
2. create or activate the in-app product `skedux_pro_lifetime`
3. make sure it is active, not draft
4. upload the release bundle to an internal testing track
5. add tester accounts
6. install from the Play internal testing link when testing purchases

Do not rely on local APK installs or `flutter run` to validate real billing behavior.

## Insurance: Do You Need Public Liability Or Professional Indemnity?

Short answer:

1. you are unlikely to be legally required to hold public liability insurance just to publish a software app as a sole trader
2. you are also unlikely to be universally legally required to hold professional indemnity insurance just to launch
3. but that does not mean going without insurance is a good idea

For a software product like Skedux, these are different questions:

### Public Liability Insurance

What it is for:

1. physical injury or property damage claims linked to your business activities
2. examples: attending events, meeting clients in person, physical premises exposure

For a mobile app business with no public premises or in-person operations, public liability may not be the highest-priority cover, but it can still matter depending on how you operate.

Practical view:

1. probably not legally required just to publish the app
2. often lower priority than professional indemnity or cyber/privacy-related cover for a software product

### Professional Indemnity Insurance

What it is for:

1. claims that your product, advice, or professional service caused financial or other loss
2. software, content, calculation, or workflow errors are more relevant here than slip-and-fall type risks

For Skedux, this is the insurance type that is more naturally aligned to the product risk profile than public liability.

Why it matters more here:

1. the app deals with medication-related records and calculations
2. users may claim reliance on app output or reminder behavior even if disclaimers exist
3. disclaimers help, but they do not guarantee you are insulated from complaints or claims

Practical view:

1. probably not universally mandatory by law for launch
2. but strongly worth discussing with an Australian broker before enabling paid monetization

### Cyber / Privacy / Tech E&O Cover

Also worth asking about:

1. cyber liability
2. privacy/data breach cover
3. technology errors and omissions cover

Because Skedux deals with health-adjacent information and platform integrations, this may be more relevant than generic public liability.

## Practical Insurance Recommendation

If you are launching with any paid monetization or meaningfully public distribution, the prudent order is:

1. speak to an Australian insurance broker familiar with software businesses
2. ask specifically about professional indemnity for software and app products
3. ask whether cyber/privacy cover is appropriate
4. ask whether public liability is necessary for your operating model

For Skedux specifically, if you can only prioritize one conversation, prioritize professional indemnity / tech E&O before public liability.

## What You Probably Need Before Paid Launch

At a practical minimum, I would want these in place before turning on Pro sales:

1. ABN
2. legitimate address solution
3. checked brand name
4. support email and website
5. privacy and legal pages
6. separate banking and records
7. accountant or tax guidance for sole trader setup
8. insurance discussion with a broker, especially around professional indemnity / tech E&O

## Safer Staged Launch Option

If any of the above is still unresolved, the lower-risk approach is:

1. launch the app free first
2. keep paid Pro disabled
3. finish the address, ABN, legal, and insurance work
4. activate Pro later

That approach is especially sensible if you are not yet comfortable with the merchant address and insurance position.

## Week-By-Week Operational Sequence

### Week 1

1. choose address path
2. check `Skedux` branding conflicts
3. decide whether to launch free first or paid

### Week 2

1. apply for ABN
2. register business name if proceeding with `Skedux`
3. register domain
4. create support email

### Week 3

1. publish the minimum website
2. open separate business banking
3. set up bookkeeping
4. speak to accountant and insurance broker

### Week 4

1. complete Google payments profile
2. activate Play billing product
3. upload internal testing bundle
4. test real Play billing through internal testing

## Final Recommendation

If you care about privacy and want a clean setup, do not rush paid monetization until the address and business basics are sorted.

For Skedux, professional indemnity / tech E&O is the more important insurance conversation than public liability, even if neither is strictly mandatory in a generic sense.