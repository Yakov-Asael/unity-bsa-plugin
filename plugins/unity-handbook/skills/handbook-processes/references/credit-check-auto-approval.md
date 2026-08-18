# Credit Check Auto Approval

> Source: BSA Process Handbook, tab "Credit Check Auto Approval". Verbatim.

**Credit Check Auto Approval**

**Process:** Credit Check — the automatic approve, reject and manual-review decision on a customer credit request · **Built on:** Credit_Check__c, two record-triggered flows and two approval processes · **Business owner:** Credit and Revenue Accounting · **Technical owner:** Dror Diamant (outgoing) → Yakov Asael

*§1–2 what it is and the two flows · §3 how every parameter is calculated · §4 the decision order · §5–8 auto-reject, auto-approve, manual review and the approval route · §9 the approval chain · §10 the emails · §11 watch-outs · §12 who to ask.*

# 1. What this process does

When an account manager needs a customer to be given credit — or to have their existing credit limit raised — they create a Credit Check record. The system then tries to make the decision itself. It either approves it outright, approves it at a lower amount than asked for, rejects it, or decides it cannot safely call it and sends it to Finance for a human decision.

The point of the automation is volume: most credit requests are routine, and Finance should only see the ones that genuinely need judgement. Everything the automation decides is stamped as automatic, so the two populations can always be told apart afterwards.

**How it runs, end to end**

**1.** An account manager creates a Credit Check on the account, choosing a record type — New for a first credit line, Change to raise an existing one — and entering a requested amount and an expected daily spend.

**2.** The first flow immediately gathers everything the decision needs: overdue balances across the whole legal entity, payment history, revenue trend, supply balances, prior collections. It writes all of it onto the Credit Check record.

**3.** The second flow reads those fields and walks a fixed sequence of gates.

**4.** The outcome is one of four: rejected automatically, approved automatically at the full amount, approved automatically at a reduced amount, or routed to a human.

**5.** If the outcome is an approval, the account's credit limit is updated in the same transaction.

**6.** The account manager gets an email telling them which of those four happened, and what to do next.

# 2. How every parameter is calculated

**The figures that drive the decision**

| **Parameter** | **How it is calculated** |
|---|---|
| Legal Entity Overdue Balance | The sum of three ageing buckets — 31 to 60 days, 61 to 90 days, and above 90 days — added together across every advertiser account in the peer group. Note what is deliberately excluded: the 1-to-30-day bucket is not counted. For this process "overdue" begins at 31 days, and an invoice that is merely a fortnight late does not count against the customer here. This single figure is what the first auto-reject gate tests. |
| Supply Overall Balance | The sum of Overall Balance across every publisher account in the same legal entity and country that has a positive balance. In plain terms: how much Unity owes this corporate customer on the supply side. It exists so that a customer Unity already owes money to is not treated as a pure credit risk. |
| Account had Revenue Spike | True when either of two things holds. Either this month's daily average revenue is more than double last month's — the formula computes half of this month's daily average minus last month's and asks whether it is positive — or the customer had no revenue at all last month and does have revenue this month. A spike means the historical numbers cannot be trusted to predict the near future, which is why it forces a human decision. |
| Daily average revenue, this month | Total revenue from the first of the month up to yesterday, divided by the number of days elapsed. The day count is today's date minus one, floored at one so that running on the first of the month does not divide by zero. Revenue is summed for the account and for its secondaries — accounts whose Invoiced with field points at it. |
| Daily average revenue, last month | Total revenue for the whole previous calendar month divided by the number of days in that month. Same account scope. If there was no revenue at all, the average is zero rather than an error. |
| Previously in Collections, and the collection notes | True if any advertiser account in the peer group has a Collection Stage of Legal, Bad Debt, External Legal or External Collector. When one is found, a text block is assembled onto the record giving the account name, the advertiser Id, the stage and the collection notes, so the reviewer can see the history without going hunting. |
| Highest credit line | The Credit Check with the largest approved amount for the same legal entity and country, approved, created within the last two years. It answers "how much have we ever trusted this customer with?". |
| Highest and last paid invoice | Two lookups over the same population — invoices of type Invoice, Paid In Full, within the last two years, matched on legal entity and country. One sorted by amount to find the largest they have ever settled, one sorted by paid date to find the most recent. |
| Open dispute | The most recent open dispute on the account that is not yet attached to an invoice. Its presence is surfaced for the reviewer; it does not itself change the automatic decision. |
| Related account info | The earliest account in the peer group to go live, with its name, advertiser Id and go-live date. This is the tenure signal — how long the corporate customer has actually been trading with Unity, as opposed to how old the particular account is. |
| Invoice payment history | Five totals summed across the peer group: invoices paid on time, paid within 1 to 30 days late, 31 to 60, 61 to 90, and over 90. Written only for the Change record type — a New credit request has no history worth summing. |

| **Field** | **How it is calculated** |
|---|---|
| Daily average, last 7 days | A formula field on the Account. The last seven days of revenue, including revenue on secondary accounts, divided by seven. This is the system's own view of what the customer spends per day, and the decision compares it against what the account manager typed in. |
| Days to reach credit limit | Also a formula on the Account: remaining credit divided by that seven-day daily average, returning zero when the average is zero. It answers "at their current rate, how long before they exhaust the credit they already have?". A large number means they do not need more credit yet. |

**The reduced-amount formula**

When the automation decides to approve but not at the full amount, this is the number it grants:

IF( Account.Credit_Amount + (Account.Daily_Avg_Last_7_Days * 10) > Requested_Amount, Requested_Amount, Account.Credit_Amount + (Account.Daily_Avg_Last_7_Days * 10) )

In words: the current credit limit plus ten days of the customer's recent spending, capped at whatever they actually asked for. It is a deliberate partial grant — enough headroom to keep campaigns running for about a week and a half while the customer produces proof of payment for what they owe, without exposing Unity to the full requested amount.

# 3. The decision order

| **#** | **Gate** | **Condition** | **If it fires** |
|---|---|---|---|
| 0 | Does the automation apply at all? | Record type is Change, AND requested amount is 250,000 or less, AND the requested amount is greater than the account's current credit limit. | If NO — skip every gate below and go straight to the approval process (§8). A New credit request is never decided automatically. |
| 1 | Collection stage or overdue balance | Account Collection Stage is Legal, Bad Debt, External Legal or External Collector, OR Legal Entity Overdue Balance is above 1,000. | Auto-reject. Reason: "The account has overdue balance or collection stage is not allowed". |
| 2 | Too many open periods | The account has three or more open invoices belonging to three or more different correction periods. | Auto-reject. Reason: "The account has 3 open invoices for different periods." |
| 3 | Amount ceiling, re-checked | Requested amount is 250,000 or less. | If NO — go to the approval process. In practice gate 0 has already enforced this. |
| 4 | Does the AM's expectation match reality? | The account's computed seven-day daily average is not equal to the Expected Daily Spend the AM entered, on a Change record. | Manual review. |
| 5 | Do they even need the credit? | Days to reach credit limit is greater than 20. | Auto-reject. Reason: "The account has more than 20 days to reach its limit." |
| 6 | Is there any payment history or offsetting balance? | A paid invoice exists anywhere in the corporate family, OR the Supply Overall Balance is at least half of the account's Overall Balance. | If NEITHER — manual review. |
| 7 | Revenue spike | Account had Revenue Spike is true. | Manual review. |
| 8 | Any recent lateness? | The 1-to-30-day balance is above 100. | Approve, but at the reduced amount from §3. Otherwise approve at the full requested amount. |

**Note the shape of gate 8.** There is no "reject" outcome at the end. By the time a record reaches gate 8 it has passed everything, so the only question left is whether to grant the full amount or a partial one. A small amount of recent lateness reduces the grant; it does not block it.

# 4. When it is rejected automatically

Three gates reject, between them covering four distinct conditions — the first gate tests two things and treats them as one outcome. All of them set Approval Status to "Rejected by Finance", mark the record as decided automatically, and write a rejection reason that the account manager sees.

| **Trigger** | **Reason written to the record** | **Why the rule exists** |
|---|---|---|
| Collection stage is Legal, Bad Debt, External Legal or External Collector | "The account has overdue balance or collection stage is not allowed" | A customer already in a collections process does not get more credit. This is checked on the account itself, not across the peer group. |
| Legal Entity Overdue Balance above 1,000 | Same reason text — the two conditions share one rejection path, so the message does not tell you which one fired. | Money more than 30 days overdue anywhere in the corporate family blocks new credit. The threshold is low enough that it is effectively "any meaningful overdue amount". |
| Three or more open invoices across three or more different periods | "The account has 3 open invoices for different periods." | A customer letting several months accumulate unpaid is a payment-behaviour risk even if none of it is formally overdue yet. Note it counts distinct periods, not invoices — ten unpaid invoices from a single month do not trigger it. |
| Days to reach credit limit above 20 | "The account has more than 20 days to reach its limit." | Not a risk rejection at all — it means the customer does not need the credit yet. At their current spend they have more than twenty days of headroom left, so the request is premature. The email for this outcome is deliberately softer than the others. |

**Worth knowing when someone disputes a rejection:** the first two share a single reason string, so "overdue balance or collection stage is not allowed" does not tell you which. Check the Collection Stage on the account first, then the Legal Entity Overdue Balance figure on the credit check.

# 5. When it is approved automatically

Only a record that has passed every gate reaches an approval, and there are two flavours.

| **Outcome** | **When** | **What is written** |
|---|---|---|
| Approved in full | The 1-to-30-day balance is 100 or less — the customer has essentially nothing outstanding even in the newest bucket. | Approval Status = Approved, Approved Credit Amount = the full requested amount, decided-automatically flag set. |
| Approved at a reduced amount | The 1-to-30-day balance is above 100. | Approval Status = Approved, Approved Credit Amount = the current limit plus ten days of recent daily spend, capped at the requested amount. |

In both cases the flow then updates the Account itself — the credit limit is set to the approved amount and the credit type is set to Credit — in the same transaction. There is no separate step and no delay: an automatic approval is live immediately.

**The reduced-amount case is a conditional approval, and the email says so.** It tells the account manager that the customer has an overdue balance, that the partial grant buys roughly an extra week of runway, and that they should obtain proof of payment and post it to Chatter on the credit check record. If nobody actions that, the customer simply runs out of credit again shortly afterwards.

# 6. When it goes to manual review

Three gates hand the decision to a human. All three set the internal action to Manual Review, send the account manager the manual-review email, and then fall through to the approval routing in §8 — the record is submitted to the approval process exactly as an un-evaluated one would be.

| **Trigger** | **Why a human is needed** |
|---|---|
| The expected daily spend does not match the computed daily average | The account manager has told the system the customer will spend a different amount from what they have actually been spending. Either the AM knows something the data does not — a campaign about to launch — or the request is based on an optimistic assumption. Neither can be judged automatically. Note this is an exact inequality, so any difference at all, however small, triggers it. |
| No paid invoice anywhere in the corporate family, and no offsetting supply balance | The automation has no evidence this customer has ever paid Unity anything, and Unity does not owe them enough to offset the exposure. There is nothing to base a decision on. |
| The account had a revenue spike | Their spending has more than doubled month on month, or has restarted after a gap. The historical averages the other gates rely on are no longer a fair predictor, so the numbers cannot be trusted. |

**The manual-review email is the most operationally important of the four.** It tells the account manager to start gathering documentation before Finance asks: audited financials or a bank statement, plus two or more trade references. And it carries a warning in red — if the customer cannot provide the documentation, the AM must request a 50% prepayment of the requested credit line to proceed. Getting that in front of the AM early is the whole point of sending it at the moment of routing rather than waiting for Finance.

# 7. When it skips the automation entirely

Gate 0 sends a request straight to the approval process without any automatic evaluation. Three situations produce this:

  - > **The record type is New.** A first credit line for a customer is never granted automatically. Every New credit check goes to Finance.

  - > **The requested amount is above 250,000.** Beyond that ceiling a human always decides, regardless of how clean the account is.

  - > **The requested amount is not actually an increase.** If the requested amount is less than or equal to the current credit limit there is nothing to evaluate, so it routes for human handling.

**Who the record is submitted to**

Before submitting, the flow checks whether a Finance Approver is set on the record. If it is empty it looks up a default — and this is worth knowing because it is hardcoded: the flow searches for a User whose name is literally "Amir Weingrod" on the System Administrator profile, and stamps that user as the Finance Approver. If that user is renamed, deactivated or moved off that profile, the lookup returns nothing and the record is submitted with no approver.

It then picks one of two approval processes:

| **Approval process** | **Submitted when** | **Note** |
|---|---|---|
| Credit Check ApprovalV4 | Record type is New AND Credit Type is Credit. | The standard route for a first credit line. |
| Credit Check Approval Change | Record type is Change AND Credit Type is Credit AND either the requested amount exceeds the current limit, or the current limit is zero and the account division is UnityAds. | The second branch exists so that a UnityAds account sitting at zero credit can be processed even when the amount comparison would not otherwise qualify it. |

**There is no fallback.** If neither rule matches — for example a Credit Type that is not "Credit" — the decision has no default outcome and nothing is submitted. The record sits with no approval process and no automatic decision, and nothing alerts anyone. If someone reports a credit check that "just did nothing", this is the first thing to check.

# 8. The approval chain

Both approval processes are active and both have the same four steps, each assigned to a user named in a field on the Credit Check record:

| **Step** | **Approver comes from** | **Note** |
|---|---|---|
| 1 | Finance Approver | Defaulted to the hardcoded user in §8 when the field is empty at submission. |
| 2 | Finance 2nd Approver | A second finance signature. |
| 3 | Business Approver | The commercial sign-off. |
| 4 | CFO Approver | Final approval. |

**Because every step reads a user field on the record,** an empty field or a deactivated user stalls the approval at that step. This is the same failure mode as everywhere else in the finance stack: the chain resolves to named people, and people leave.

When a human eventually approves the record, Flow A fires again and writes the balance and payment-history snapshot described in §2.

# 9. The emails

Every outcome sends exactly one email to the account manager, from the org-wide do-not-reply address. They are HTML templates built inside the flow, not Salesforce email templates, so they are edited in Flow Builder.

| **Outcome** | **Subject** | **What it tells the AM to do** |
|---|---|---|
| Approved in full | Credit Approved + account name | Nothing — informational. Questions go to Finance via Chatter on the record. |
| Approved at a reduced amount | Credit Approved / Action Required + account name + Overdue Balance Notice | States the new limit, explains that the customer has an overdue balance and that the partial credit buys about a week, and asks the AM to obtain proof of payment and post it to Chatter. |
| Rejected on collection stage or overdue balance | Action Required: Credit Check Rejected + account name + Overdue Balance | Gives two routes forward: obtain proof of payment for the overdue balance and post it to Chatter, or wait until the balance clears and raise a new credit check. |
| Rejected because they do not need it yet | Update on Credit Request + account name | Deliberately gentle. Says the available credit line is sufficient for the current spend level, and invites the AM to come back to Finance if the customer's plans have changed materially. |
| Manual review | Action Required: Credit Request + account name + Under Manual Review | The documentation checklist and the 50% prepayment warning described in §7. |

**One condition applies to all five.** The email only sends if the account manager on the account is active, or the person who created the credit check is active. If both are inactive the decision still happens, the record is still updated — and nobody is told. There is no default branch on that decision.
