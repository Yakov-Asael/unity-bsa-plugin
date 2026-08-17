# Deals

> Source: BSA Process Handbook, tab "Deals". Verbatim.

**Deal**

**Process:** non-standard deals — the Ads Deal Desk opportunity, its incentives and the disputes that pay them out · **Built on:** Opportunity, incentive__c, Offer__c and Dispute__c, one screen-flow wizard, two approval processes and a family of approver-matrix records · **Business owner:** the Grow Deal Desk — Tal Rahamim, Bar Damti, Elad Zommer · **Technical owner:** Dror Diamant → Yakov Asael

*§1–2 what it is and where it lives · §3–5 creating the deal, its incentives and its tiers · §6 approval · §7–8 disputes · §9 the Supply/Demand summary · §10 troubleshooting · §11–12 watch-outs and who to ask.*

**Read this first.** There is no Deal object. The deal is an Opportunity — record type labelled Ads Deal Desk, developer name Mobile_Growth. Every link, report and flow you will meet points at /lightning/r/Opportunity/. There is a custom object called Deal__c in this org and it is a different thing entirely; ignore it. What is called "the deal" everywhere in the business is the opportunity, its child incentives, and the disputes those incentives generate.

# 1. What this process does

Most Unity Grow business runs on standard rate cards. A minority does not — mediation deals, offerwall partnerships, network growth initiatives, upsells and performance-based rebates. Those are non-standard deals, and this process is how they are structured, approved, tracked and paid.

The Grow Deal Desk describes itself as "the central coordination hub between sales, finance, legal, and business operations". Before this existed, non-standard deals were approved over email, Slack and offline conversations. The process replaced that with a Salesforce wizard, a visible approval chain, and a record of every payment owed.

**The chain end to end**

**1.** A salesperson opens the deal wizard from an account, or from an existing pipeline opportunity.

**2.** The wizard creates an Opportunity on the Ads Deal Desk record type — this is the deal.

**3.** On the same wizard they define one or more incentives: what the customer must achieve, and what Unity pays or discounts when they achieve it.

**4.** Each tiered incentive gets its tier table written underneath it.

**5.** The deal goes through an approval chain that differs between Supply and Demand.

**6.** Once signed and closed won, someone presses Create Disputes on the deal. The system generates one dispute per payment period, all at zero.

**7.** Each period the owner opens the relevant dispute, enters the amount actually earned, attaches proof of performance and submits it for approval.

**8.** An approved dispute creates a bill. That is the money leaving.

# 2. The moving parts

| **Piece** | **Name** | **What it does** |
|---|---|---|
| **The records** | | |
| The deal | Opportunity, record type Ads Deal Desk (DeveloperName Mobile_Growth, Id 0120N000000AXyxQAG) | Holds the commercial terms, the classification, the contract dates, the approval fields and the maximum exposure. Note the label and the developer name do not match — search for either and you may miss the other. The Id is hardcoded into several flows in both its 15- and 18-character forms. |
| The promise | incentive__c | A child of the opportunity. One per bonus or rebate structure. This is where the payment frequency, basis, method and tier count live. |
| The tiers | Offer__c | Child of the incentive. Holds the tier thresholds and the tier amounts — see §5, because the shape is not what you would expect. |
| The payment request | Dispute__c | Linked back to the deal through Deal__c, a lookup to Opportunity (relationship name Disputes1). Record types Supply dispute and Demand dispute. |
| The accounts on the deal | Deal_Accounts__c | Written by the wizard when a deal spans more than one account — for example a mediation and offerwall deal recorded on the iAds publisher account. |
| **The automation** | | |
| Creation wizard | Create Opportunity Deal Ads (screen flow, Active) | The single entry point. Creates the opportunity, the deal accounts, the incentives and the tier rows. Launched from the Create Deal action on Account, or Move Opportunity to Deal / Create Renewal Deal on Opportunity. |
| Supply approval | Deal_Approval_Process_v4 (Active) | Four steps. §6. |
| Demand approval | Demand_Deal_Approval_Process_V2 (Active) | Four steps, a different four. §6. |
| Dispute generation | Create Disputes (quick action) → Deal - Create Supply Deal Dispute (screen flow, Active, version 3) | The button on the deal that generates the whole payment schedule at once. Note this flow is not in the metadata repository — it was built directly in production, so Flow Builder is the only place to read it. |
| Dispute routing | Dispute - Set dispute approvers (Active) | Decides who approves each dispute, and whether it is approved automatically. §8. |
| Dispute count rules | Supply_Deal_Num_of_disputes__mdt | Eight metadata records that turn a payment frequency into a number of disputes. §7. |
| Approver lookup | Approver_Matrix__c and Dispute_Amount_Level__mdt | The routing tables for both deal approval and dispute approval. |
| **Deliberately excluded from this guide** | | |
| Retired | Deal Payment | Superseded by disputes. Do not build on it. |

# 3. Creating the deal

Everything starts in one screen flow. It takes a single input — the Id of whatever record you launched it from — and looks that Id up as both an Account and an Opportunity. Whichever query returns a record decides which path you are on. That is the mechanism behind the two entry points people describe differently.

| **Entry point** | **Used for** | **What happens** |
|---|---|---|
| From the Account | New business and, on Demand, everything | The account lookup returns; the opportunity lookup is empty. The wizard builds a brand-new opportunity from scratch. |
| From an existing pipeline Opportunity | Supply new business and upsells | The opportunity lookup returns. The wizard carries the existing opportunity's context into the new deal. |
| From an existing deal | Renewals and retention | A separate creation branch runs, and the new deal is linked back through Original Deal and Renewal Deal. |

**Where Supply and Demand split inside the wizard**

The wizard branches on a single variable, Department, which is either Publisher or Advertiser. Three of its decisions behave differently as a result:

  - > **Which department.** The top-level fork. Everything downstream — deal types offered, fields shown, approval process submitted to — follows from it.

  - > **Does it need an integration-fee incentive.** True only when Department = Publisher and an integration fee amount was entered. Integration fees are a Supply concept; the branch cannot fire on Demand at all.

  - > **Does it have incentives.** True when the deal is not integration-fee-only, and — on the Demand side only — when the deal type is not UA Bonus. A Demand UA Bonus deal deliberately creates no incentive record.

**One convention that is not enforced anywhere:** when a deal covers several products, it must be recorded on the main account. The enablement doc gives the example — a mediation and offerwall deal belongs on the iAds publisher account. Nothing validates this, and getting it wrong sends the disputes to the wrong place later.

# 4. Incentives — what they are and when they are created

An incentive is a performance-based commitment attached to the deal. The business calls it different things on each side, and the difference is real:

  - > **On Supply it is money out.** A payment to the publisher for hitting a performance target — the glossary calls these Milestone Bonuses. Separately there is the Integration Fee, also known as the Signing Bonus: a fixed amount paid for reaching the minimum contract start terms. The documentation is emphatic that the integration fee is not a performance bonus.

  - > **On Demand it is money off.** An Advertiser Incentive Plan, or rebate — a discount that encourages the client to spend more, usually measured on aggregated monthly or quarterly spend, paid as a percentage or fixed amount per spend tier.

**The two moments an incentive is created**

| **Trigger** | **What gets written** |
|---|---|
| You fill in the Incentive screen in the wizard | One incentive__c per structure you define, with the values you chose: Department, Network (iAds / uAds / Tapjoy), Payment Frequency, Payment Method, Payment Structure (Fixed or Tiered), Incentive Basis, Incentive Payment Terms (% of or Fixed Amount), how many tiers, TMR type, notes, and — where the payment method is UA Credits — the Demand Account it will be credited against. |
| Department = Publisher and an Integration Fee Amount was entered | A second incentive__c is created automatically, entirely from hardcoded values: Name "Integration Fee", Department Publisher, Payment Frequency "One Time Integration Fee", Incentive Basis "Upon Agreed Min Terms", Incentive Payment Terms "Fixed Amount", Payment Method "Cashback". The user never sees this screen and cannot change these values. |

**So a Supply deal with an integration fee and a monthly bonus has two incentive records, not one.** That matters, because the number of disputes generated later is the sum across every incentive on the deal.

**How many incentives a deal may have**

On Supply there is no limit — the enablement doc says so explicitly and gives the example of one incentive based on TMR and another based on DAU for a combined mediation and offerwall deal. On Demand the wizard offers a main incentive plus an optional additional one, described in the documentation as rare.

**The incentive fields worth knowing**

| **Field** | **Values and meaning** |
|---|---|
| Payment_Frequency__c | One Time Payment Yearly, One Time Payment Quarterly, Performance Bonus Prepayment, Monthly Bonus, Quarterly Bonus, Yearly Bonus, Half Yearly Bonus, Monthly Rebate, Quarterly Rebate, One Time Integration Fee. This single field decides how many disputes the deal produces (§7). |
| Incentive_Basis__c | What is being measured: TMR, Network Monthly Payout, DAU, Daily Engaged Users, Daily Network Spend, Network Quarterly Spend, Network Monthly Spend, Upon Agreed Min Terms. Supply deals typically use TMR or payout; Demand uses Daily Network Spend. |
| Payment_Method__c | Cashback, UA Credits, Credits for Additional Services, Prepayment. UA Credits is the one that reaches across sides — see below. |
| Payment_Structure__c | Fixed or Tiered. Tiered means the tier table in §5 is populated. |
| Demand_Account__c | Only relevant when the payment method is UA Credits. A Supply deal paying the publisher in advertising credit needs to know which Demand account receives them. |
| Disputes_Created__c and of_Disputes_created__c | The flag and the count set when the payment schedule has been generated. These are what stop the Create Disputes button running twice. |

**The cross-side case.** When a Supply incentive is paid as UA Credits, the resulting dispute is not a Supply dispute. It is created against the nominated Demand account, on the Demand Dispute record type, with reason UA Bonus - Integration Incentive, and as a Deduction rather than a Positive Discrepancy. A Supply deal can therefore produce Demand disputes, which is unexpected the first time you see it.

# 5. Tiers — a data model that will surprise you

An incentive can have up to five tiers, each a minimum threshold and the amount or percentage earned at that threshold. You would reasonably expect one Offer__c record per tier. That is not how it works.

The wizard creates exactly two Offer__c records per tiered incentive, and stores the tiers sideways across numbered columns:

| **Offer record** | **What its columns hold** |
|---|---|
| The threshold row | X1st_Range__c through X4th_Range__c hold the four tier minimums — the level the customer has to reach. |
| The amount row | X1st_Range__c through X4th_Range__c hold the four corresponding payouts or percentages. |

**Two consequences.** First, reading a tier means joining two records positionally — tier 3's threshold is on one row and its amount is on the other, and nothing but column position links them. Second, the object has columns up to X7th_Range__c but the wizard only ever populates four, so a five-tier incentive cannot be fully expressed through the wizard even though the picklist offers 5.

Two roll-up summaries on the Opportunity read from these records: Deal Signing Bonus and Deal Recoupment in Months. If a tier row is deleted or rebuilt by hand, those roll-ups move.

**A related instruction from the business, worth repeating verbatim:** if the deal is not tiered, fill in only the Tier 1 field and leave the rest blank. And on Demand, if the client earns a discount from the first dollar, the Tier 1 threshold should be set to 0.

# 6. Approval — two chains, one per side

Both processes are active, both have four steps, and they are not the same four.

| **Step** | **Supply — Deal_Approval_Process_v4** | **Demand — Demand_Deal_Approval_Process_V2** | **Approver source** |
|---|---|---|---|
| 1 | Deal Desk approval | — | Supply only. A named user, hardcoded into the process. |
| 2 | VP Approval | VP Approval | The SDROwner__c field on the deal, filled in by the wizard from the approver matrix. |
| 3 | FP&A Approval | FP&A Approval | Global_Biz_Dev__c. |
| 4 | Revenue Accounting Approval | Revenue Accounting Approval | Finance_Approver__c. |
| 5 | — | Chief Financial Approval | Demand only. Chief_Financial_Approver__c. |

**The two differences in one line:** Supply starts with a Deal Desk gate that Demand does not have; Demand ends with a CFO gate that Supply does not have.

**The approver fields are stamped at creation, not at submission.** The wizard reads Approver_Matrix__c once, using the deal type, division, department, upsell type and amount, and writes the result onto the opportunity. If the matrix is wrong, or if the person it names has since left, the deal carries a dead approver and gets stuck. That is the single most reported problem in this process — see §11.

Older versions of both processes are still present in the org — Deal_Approval_Process_v2, v3 and the first Demand_Deal_Approval_Process. Check the version number before assuming which one you are looking at.

# 7. From deal to disputes

Once the deal is signed and closed won, the payment schedule is generated in one go. Someone presses Create Disputes on the opportunity, which launches the screen flow Deal - Create Supply Deal Dispute.

**What the button asks, and when it appears**

The button is exposed only when the opportunity is Closed Won, the minimum contract term is filled in, the integration-fee-only flag is set one way or the other, and disputes have not already been generated. It then asks one question — have the minimum terms been met? Answer No and it refuses with an error. Answer Yes and it takes the go-live date and builds the schedule.

**How many disputes get created**

There is no cap and no manual count. The number is derived, per incentive, from its payment frequency and the contract length. Eight metadata records in Supply_Deal_Num_of_disputes__mdt do the arithmetic:

| **Payment frequency** | **Divisor** | **Disputes for a 24-month deal** |
|---|---|---|
| Monthly Bonus | 1 | 24 |
| Quarterly Bonus | 3 | 8 |
| Half Yearly Bonus | 6 | 4 |
| Yearly Bonus | 12 | 2 |
| **Flagged as one-time — always exactly 1 dispute, regardless of contract length** | | |
| One Time Integration Fee | — | 1 |
| One Time Payment Yearly | — | 1 |
| One Time Payment Quarterly | — | 1 |
| Performance Bonus Prepayment | — | 1 |

**Worked example from the design doc:** a 24-month deal with an integration fee, a quarterly mediation bonus and a monthly offerwall bonus produces 1 + 8 + 24 = 33 disputes in a single click. That is normal. Do not delete them.

**What each dispute looks like when it is born**

| **Attribute** | **Value at creation** |
|---|---|
| Amount | Zero on the Supply side — the owner fills it in each period. On Demand, UA bonus disputes are created at the deal's approved amount rather than at zero. |
| Deal | The lookup back to the opportunity. A dispute with reason "Supply deal incentives" and no deal is invalid and cannot be created. |
| Automatic_Deal_Dispute__c | True. This flag is what tells the routing flow the dispute came from a deal rather than from an account, and it changes the entire approval path (§8). |
| Activity period | Calculated forward from the go-live month — month N for monthly, every third month for quarterly, and so on. |
| Reason for dispute | Supply: "Supply deal incentives". Demand: "Adv Incentive Plan", "UA Bonus", or "UA Bonus - Integration Incentive". |

**The monthly routine**

Per payment period, the owner opens the deal, finds the dispute for that activity month, enters the amount earned, attaches proof that the agreed terms were met, and submits it. The business deadline is the 15th of each month. Where the client did not reach the tier, the dispute is not submitted — its status is set to Not Eligible for Payment instead. On the Supply side that is done by the Client Partner, or by the Sales Manager for SMB accounts; on the Demand side the Deal Desk team closes it.

**Three validations to know about:** a dispute of this type cannot be submitted without an attachment; Finance cannot approve until bill type and bill activity period are filled in; and two disputes for the same deal, division and activity month are blocked as duplicates. When a dispute is approved, a bill is created and the dispute is closed against it.

# 8. Who approves a dispute

One flow decides, on create and on any change to the amount: Dispute - Set dispute approvers. It skips delta disputes, skips the SuperSonic division, and re-runs whenever the amount changes unless the person changing it holds the Revenue Accounting permission.

It then picks one of three different lookups into Approver_Matrix__c, and which one it picks is the heart of the Supply/Demand difference:

| **Path** | **How the approver is found** |
|---|---|
| Supply deal dispute | Matched on Approver_1_Long_ID__c = PaymentApproverSupplyDeal, Dispute Type = Supply Deal, Department = Publisher, and the team. Note what is absent: there is no amount band in this lookup. A supply deal dispute routes the same way whether it is for one hundred dollars or one hundred thousand. |
| Demand deal dispute | Matched on Approver_1_Long_ID__c = PaymentApprover with Approver_4__c empty, plus dispute type, division and department. |

**This explains a real incident worth carrying forward.** Two revenue-share incentive disputes behaved differently — one reached Revenue Accounting, the other did not. The cause was that both had been opened from the account rather than from the deal, so neither carried the deal flag, and both fell through to the standard amount-banded path. The larger one cleared the band and got Revenue Accounting; the smaller one did not. Revenue Accounting's position is that every supply deal incentive dispute should reach them regardless of amount, and the deal path already does exactly that. The fix is to stop people creating these from the account.

# 9. Supply and Demand, side by side

Everything above, collected. Where a row says the same thing twice, it genuinely is the same.

| | **Supply — Publisher** | **Demand — Advertiser** |
|---|---|---|
| **Creating the deal** | | |
| Started from | An existing pipeline opportunity or the account. Renewals and retention start from the existing deal. | The account. Create Deal on the account page. |
| Typical contract length | 12 to 24 months. | 12 months. |
| Integration fee | Yes — and it silently creates a second incentive record. | Not available. The wizard branch cannot fire. |
| Deal types | Mediation, OW, Network, Mediation + OW, OW + Network, Revenue Share. | Advertiser Incentive Plan / Recurring Performance Rebate, UA Bonus (Compensation and Performance Incentive), GPS PAD, GPS SDK Renting Fee. |
| **Incentives** | | |
| What it is | A payment out to the publisher for performance. Called a Milestone Bonus. | A discount to the advertiser conditioned on spend. Called a rebate. |
| How many | Unlimited. | One main, plus an optional additional one described as rare. |
| Usual basis | TMR or network payout. | Daily Network Spend. |
| Special case | A UA Credits payment method creates a Demand dispute against a nominated Demand account. | A UA Bonus deal type creates no incentive record at all. |
| **Approval** | | |
| Chain | Deal Desk → VP → FP&A → Revenue Accounting. | VP → FP&A → Revenue Accounting → CFO. |
| **Disputes** | | |
| Record type | Supply dispute. | Demand dispute. |
| Reason | Supply deal incentives. | Adv Incentive Plan, UA Bonus, UA Bonus - Integration Incentive. |
| Opening amount | Zero. | Zero, except UA bonuses which are created at the approved amount. |
| Approver lookup | By team only — no amount band. | By dispute type, division and department. |
| Who updates each period | Client Partner, or Sales Manager for SMB. | Account Manager. |
| If the tier was not reached | The CP or SM sets the status to Not Eligible for Payment. | The Deal Desk team closes the dispute. |

# 10. Troubleshooting

**"I cannot submit the dispute — the approver field is empty"**

By far the most common report. Work through it in this order:

**1.** Check the dispute came from the deal. If Automatic_Deal_Dispute__c is false, it was created from the account and is on the wrong path entirely. That is the root cause more often than the matrix is.

**2.** Check the account manager is still active. The matrix lookup keys on the AM's team, and a departed AM breaks it. Several incidents traced back to exactly this.

**3.** Check the matrix row exists. Approver_Matrix__c needs a row matching object, approver key, team, dispute type, division and department. A missing combination returns nothing and leaves the field blank.

**4.** Check the approver named in the row is still at the company. A leaver in the matrix produces the same symptom as a missing row.

**5.** For non-deal disputes only, check the amount band. Dispute_Amount_Level__mdt must have a band covering that amount for that division, department and type. An amount above the highest maximum matches nothing.

**"The Create Disputes button is not there"**

Four conditions gate it, and all four must hold: stage is Closed Won, minimum contract term is populated, the integration-fee-only flag is set, and disputes have not already been generated for this deal. The last one is the usual answer — check Disputes Created on the incentives.

**Other known failures**

| **Symptom** | **Cause** |
|---|---|
| A UA Bonus deal has no incentive and the CP is confused | Working as designed — the wizard skips incentive creation for Demand UA Bonus deals. The recurring mistake is CPs opening a UA bonus as an Advertiser Incentive Plan instead, which forces them to create incentives and generates the dispute incorrectly. |
| Duplicate disputes for the same month | Someone created a dispute by hand instead of using the auto-generated one. A duplicate block exists on deal, division and activity month, but people work around it by creating from the account. |
| The deal was marked integration-fee-only but has incentives | A tagging error. The instruction from the Deal Desk is blunt: do not mark Integration only deal if it has incentives. |
| The contract was signed outside the deal opportunity | Happens when legal work starts before the deal record exists. The two have to be connected by hand afterwards and the deal closed won. |
| A dispute of this type will not attach to Snapsource | By design — send to finance cannot be set to true for deal incentive disputes. |


# 11. Who to ask, and what to read

| **Topic** | **Person** |
|---|---|
| The deal process end to end, commercial guidelines, thresholds | Tal Rahamim — Grow Deal Desk. Owns the playbook and the approval matrix. |
| The Demand side specifically | Bar Damti. Wrote the Demand process and is the first approver on several Demand chains. |
| The Supply side and the original wizard | Amir Tapiro, with David Amar for the business rules. |
| Revenue Accounting on disputes and bills | Shirel Kaver and Maria Zakomorni. |
| FP&A | Andrew Montelongo; Jeff Cha and Jacky Wang can both approve on behalf of FP&A. |
| The Salesforce build | Dror Diamant (outgoing) → Yakov Asael, with Shiraz Koretz on the original solution. |

**The documents worth reading, in order**

| **Document** | **Why** |
|---|---|
| [Grow Deal Desk Playbook](https://docs.google.com/document/d/1Dfri2IK9bjXN-kbURAhSDcqt2WLHV1wsR6bN5p7qYWQ) | The single best source. Covers both sides, the commercial guidelines, the bonus percentages, the recoup and exit terms, and every named partner across Finance, Legal and FP&A. |
| [Upsells & Non Standard Deals 2.0 in SFDC (Supply Only)](https://docs.google.com/document/d/1MFy7ryvlAXuC_lA_EymkP1Q4_SmNa_s5e44WDOrgxh0) | The Supply wizard, screen by screen, with the glossary that defines incentive versus integration fee. |
| [Non-standard Demand Deals Salesforce Process](https://docs.google.com/document/d/1VCSEcTOTy7UnMLBFgFbajOtCqZmlgQAIOuqZCznyHzI) | The Demand equivalent. Read both — the differences are the point. |
| [PRD - Supply Deal Disputes](https://docs.google.com/document/d/1meAuE2t3af76esaKk1AU-gnVNfLOuXlngVa36bOMDZM) | Field-level design of dispute generation: the button gating, the counts, the validations, the alerts and the bill mapping. |
| [Deal payments `<>` Disputes](https://docs.google.com/document/d/1qA-IeoR2sjtuM6A75Js9FwJkhWouO_3vI1kRjSY6fG8) | The migration PRD. Also where the open questions and the planned rename live. |
| [Team's approval matrix Deals](https://docs.google.com/spreadsheets/d/1__kgQsf7gP9IYL8jm2Lfne8uDbJ78tdQ_0uwSbR3Fs4) | The routing table as the business maintains it, region by region. Note it contains broken references — treat it as indicative, and the Approver_Matrix__c records as authoritative. |
| [Deal Desk wishlist](https://docs.google.com/spreadsheets/d/1RHlShi-1NyXC5fFN6whpcbvrXt0iEfvKfORfJ2r2F1Q) | The backlog, with exact field and flow API names. Useful for working out why something is half-built. |
