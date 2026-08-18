# Symptom index — routing a ticket to the right file

The routing table in `SKILL.md` routes by **topic** ("disputes", "the portal"). Tickets don't arrive as topics — they arrive as symptoms, often without naming the process at all. This index maps the way people actually describe problems to the file that answers them.

**This index does not contain answers.** It points at a file and the section inside it. Read the file for the answer, always — duplicating answers here would create a second copy to drift. If a symptom below leads to a file whose content has changed, the file wins.

**Route by section title, never by number.** The source's `§n` numbering is unreliable (several files cross-reference renumbered or non-existent sections), so this index names sections by title.

---

## Where each file keeps its symptoms

Worth knowing before you search a file, because the shape differs:

| File | Symptom content lives in | Format |
|---|---|---|
| `bills-invoice-sync.md` | **The whole file** — sections "Problems — the invoice or bill was never created" through "Problems — timing and delivery" | Table; symptom in column 1, plain description |
| `dispute.md` | "FAQ" | Table; column 1 is a verbatim user quote |
| `connect-360.md` | "FAQ" | Table; verbatim user quote |
| `handover.md` | "FAQ" | Table; verbatim user quote |
| `knowledge.md` | "FAQ" | Table; verbatim user quote |
| `game-design-revenue-consultancy.md` | "FAQ" | Table; verbatim user quote |
| `pipeline-summary.md` | "FAQ" | Table; verbatim user quote |
| `customer-community.md` | "Troubleshooting" | **Bold quoted headings**, not a table |
| `deals.md` | "Troubleshooting" | **Bold quoted headings** |
| `gps.md` | "Troubleshooting" | **Bold quoted headings** |
| `csat.md` | "Troubleshooting" | **Bold quoted headings** |
| `credit-check-auto-approval.md` | **No troubleshooting section.** Symptoms are answered from "The decision order", "When it is rejected automatically", "When it is approved automatically", "When it goes to manual review", "When it skips the automation entirely" | Prose + tables |

`bills-invoice-sync.md` also opens with "The five causes behind almost everything" — **check that first** for any invoice or bill incident, before working through the symptom sections.

---

## Start here — the highest-volume symptoms

### Invoices and bills

| The ticket says | File | Section |
|---|---|---|
| Invoice/bill was never created; nothing generated for an account or a whole division | `bills-invoice-sync.md` | "Problems — the invoice or bill was never created" |
| Amount is wrong; header doesn't match the lines; negative or zero amount | `bills-invoice-sync.md` | "Problems — the amount is wrong" |
| Wrong account, wrong subsidiary, wrong billing address | `bills-invoice-sync.md` | "Problems — wrong account, subsidiary or address" |
| Stuck in approval; "No invoice approver defined for this invoice" | `bills-invoice-sync.md` | "Problems — stuck in approval" |
| Approved in Salesforce but never reached Workday | `bills-invoice-sync.md` | "Problems — approved in Salesforce, never reached Workday" |
| Credit note, reversal or dispute didn't land on the document | `bills-invoice-sync.md` | "Problems — disputes, credits and reversals" |
| Invoice arrived late, or the customer never received it | `bills-invoice-sync.md` | "Problems — timing and delivery" |
| Can't see or use the Invoice/Bill Management screen; a button is missing | `bills-invoice-sync.md` | "Who can use the screens — it all hangs on one field", then "The buttons, and exactly when they appear" |

### Disputes

| The ticket says | File | Section |
|---|---|---|
| Approved the dispute but there's no Attach button | `dispute.md` | "FAQ" |
| Dispute not showing on the invoice despite being approved and attached | `dispute.md` | "FAQ" |
| "I cannot submit the dispute because I am missing approver" / approver field empty | `dispute.md` | "FAQ", then "The approver matrix" |
| Approver left the company; approvals stuck on a departed employee | `dispute.md` | "The approver matrix" — approvers are stamped at creation, not resolved live |
| "No approval process was found" on submit | `dispute.md` | "FAQ", then "Approval processes — what exists and what triggers each" |
| Auto-approved under the threshold, now can't recall or modify | `dispute.md` | "FAQ" |
| Attached to the wrong invoice; can't re-attach | `dispute.md` | "FAQ" |
| Can't untick "waiting for next invoice"; when will it attach? | `dispute.md` | "FAQ" — **and see "Timing questions" below** |
| "Blocked by finance team" when creating a dispute | `dispute.md` | "FAQ" — creation is closed during monthly close |
| Fraud amount pop-up firing when the amounts do match | `dispute.md` | "FAQ", then "Validation rules — what blocks users and why" |
| Wrong Channel for an iAds account | `dispute.md` | "FAQ" |
| Dispute has no approver, on a GPS account | `gps.md` | "Troubleshooting" → *"The dispute has no approver"* |
| Can't submit a dispute from a deal; approver field empty | `deals.md` | "Troubleshooting" → *"I cannot submit the dispute — the approver field is empty"* |
| The Create Disputes button is missing on an opportunity | `deals.md` | "Troubleshooting" → *"The Create Disputes button is not there"* |

### Connect 360 and GDRC (both called "tickets")

**Disambiguate first.** "Ticket" means a Connect 360 `Performance_Manager_Request__c`, a GDRC `Game_Monetization` Case, or a `/centro gtm` support request. Ask which if it isn't obvious from the symptom.

| The ticket says | File | Section |
|---|---|---|
| Can't move a card to Done; Follow Up button missing | `connect-360.md` | "FAQ" |
| "My Connect 360" shows tickets not assigned to them | `connect-360.md` | "FAQ" |
| Emoji didn't create a Centro ticket; error opening a ticket via Centro | `connect-360.md` | "FAQ" |
| Wrong task type for the product | `connect-360.md` | "FAQ", then "Other mappings in the process" |
| OW team not getting Slack notifications | `connect-360.md` | "FAQ", then "Notifications" |
| Blank tile / Subject not showing on the Kanban | `connect-360.md` | "FAQ" |
| Can't move a status: to do → in progress, suspended → in progress, → Delivered | `game-design-revenue-consultancy.md` | "FAQ", then "Validations — everything that can block a user" |
| "You can't create a case for the Game Design & Revenue Consultancy team from here" | `game-design-revenue-consultancy.md` | "FAQ" |
| Application name must already exist; game still in development | `game-design-revenue-consultancy.md` | "FAQ" |
| Approval email for cases already running | `game-design-revenue-consultancy.md` | "FAQ" |
| Escalation never reached leadership on Slack | `game-design-revenue-consultancy.md` | "FAQ", then "Notifications" |

### Handover

| The ticket says | File | Section |
|---|---|---|
| Approved handover never advanced to "HO complete" | `handover.md` | "FAQ" — execution runs on a fixed calendar, not on approval |
| Can't submit an HO request for approval | `handover.md` | "FAQ", then "Validation rules — what blocks users and why" |
| "You can't create hand over request for this account" | `handover.md` | "FAQ" |
| Went to an approver not in my matrix | `handover.md` | "FAQ", then "The approver matrix" |
| Stuck because the current account manager has left | `handover.md` | "FAQ" |
| Account still flagged unmanaged on Unity Dashboard after HO completed | `handover.md` | "FAQ" |
| Created an HO by accident; need it deleted or rejected | `handover.md` | "FAQ" |
| HOs rejected the instant they were submitted | `handover.md` | "FAQ" |
| Approved my own HOs, still on the current owner | `handover.md` | "FAQ" |
| Commission numbers missing for handovered accounts | `handover.md` | "FAQ" — FP&A picks up completed handovers monthly |

### Knowledge and the portal

| The ticket says | File | Section |
|---|---|---|
| Can't tick "Visible In Public Knowledge Base" | `knowledge.md` | "FAQ" |
| Article published but customers can't find it | `knowledge.md` | "FAQ", then "The Customer Community — visibility, ratings and promoted articles" |
| Customer asked to log in to read an article link | `knowledge.md` | "FAQ" → then `customer-community.md` "Public and private — the guest story" |
| Promoted article disappeared after an update | `knowledge.md` | "FAQ" |
| Reviewer can't be chosen; not getting reviewer notifications | `knowledge.md` | "FAQ", then "Who reviews each article" |
| "Create New article" button missing on most Cases | `knowledge.md` | "FAQ" |
| Team can't edit their own articles or see others' | `knowledge.md` | "FAQ" |
| Customer says their ticket isn't in the portal | `customer-community.md` | "Troubleshooting" → *"A customer says their ticket is not in the portal"*, then "Who can see which case — the whole chain" |
| Case created on the wrong account from a portal form | `customer-community.md` | "Troubleshooting" → *"The case was created on the wrong account"*, then "Submitting a request — how a form becomes a Case on the right account" |

### CSAT

| The ticket says | File | Section |
|---|---|---|
| Customer rated it and nothing shows | `csat.md` | "Troubleshooting" → *"The customer says they rated it and nothing shows"* |
| Customer didn't get a CSAT email at closure | `csat.md` | "Who gets a CSAT email at closure, and who does not" |
| CSAT field values look wrong or contradictory | `csat.md` | "Field names that will mislead you" |

### Pipeline Summary

| The ticket says | File | Section |
|---|---|---|
| An opportunity doesn't appear in pipeline review | `pipeline-summary.md` | "FAQ", then "What makes an opportunity appear" |
| Sees everyone's opportunities, or only their own, unexpectedly | `pipeline-summary.md` | "FAQ", then "Who sees what — the three visibility tiers" |
| Summary numbers don't match the table | `pipeline-summary.md` | "FAQ" |
| Can't update an operational opportunity; error saving closed-lost | `pipeline-summary.md` | "FAQ", then "What blocks users, and why" |
| Opportunity vanished after setting a go-live date | `pipeline-summary.md` | "FAQ" |
| Wrong table heading (Demand table labelled Supply); where's the export | `pipeline-summary.md` | "FAQ" |

### GPS

| The ticket says | File | Section |
|---|---|---|
| Invoice went to the brand but the agency pays | `gps.md` | "Troubleshooting" → *"The invoice went to the brand, but the agency pays"* |
| Opportunity splits disappeared | `gps.md` | "Opportunity Split" — changing the owner deletes every split, silently |
| Lead didn't match to the right account | `gps.md` | "Matching a lead to an existing account" |
| Contact fields missing / behaving oddly | `gps.md` | "Record types, layouts and the Contact surprise" |

### Credit check

`credit-check-auto-approval.md` has no troubleshooting section — work from the decision logic instead.

| The ticket says | Section |
|---|---|
| Why was this approved / rejected automatically? | "The decision order", then "When it is rejected automatically" / "When it is approved automatically" |
| Why is this in manual review? | "When it goes to manual review" |
| The automation didn't run at all | "When it skips the automation entirely" |
| The approved amount is lower than requested | "How every parameter is calculated" — the reduced-amount formula |
| Who approves it, and why did they get the email? | "The approval chain", then "The emails" |

---

## Cross-process symptoms

Where the symptom does not tell you which process owns it. Read the primary file first; open the second only if the answer is genuinely incomplete.

| Symptom | Primary | Then |
|---|---|---|
| Dispute approved but the invoice never changed in Workday | `dispute.md` | `bills-invoice-sync.md` |
| A deal generated wrong or missing disputes | `deals.md` | `dispute.md` |
| Article not visible to a customer | `knowledge.md` | `customer-community.md` |
| CSAT submitted from the portal didn't register | `csat.md` | `customer-community.md` |
| Invoice on the wrong entity for an agency/brand structure | `gps.md` | `bills-invoice-sync.md` |
| Approvals stuck on someone who left | The process's own file — approver matrices are per-process | Confirm the person's status before answering |
| "The approver matrix is wrong" | **Ask which process.** Dispute, Deals and Bills/Invoice each maintain a separate matrix with different owners | — |

---

## Timing questions — do not answer from this handbook alone

Any ticket asking **when** something will happen — "when will my dispute attach?", "when does the next invoice run?", "when will the bill generate?" — is a schedule question. Batch schedules are org configuration and appear **nowhere** in these files.

Hand off to `handbook-code-lookup`. It reads `CronTrigger` and returns the live cron expression, its timezone, and whether the job is actually running or paused.

This is not a hypothetical gap. Asked when the next bill/invoice cycle attaches, a handbook-only answer was invented, because the Dispute tab describes the "waiting for next invoice/bill" flag and links a document about the batch while stating no times at all. **Never infer a schedule from the fact that a batch exists.**

---

## Before sending a ticket reply

The handbook is a **snapshot from 9–10 August 2026**, and a ticket reply is usually read as a commitment. So:

- **Never promise a date or a cycle** from this handbook. Verify the schedule via `handbook-code-lookup` first.
- **Never paste an unverified threshold, approver name or permission grant** into a customer- or stakeholder-facing reply. Either verify it (`handbook-refresh`) or state it as the documented August 2026 position.
- **Say who can act.** These files consistently distinguish what the requester can self-serve from what needs Business Operations or the SFDC team — for example, only Business Operations or the SFDC team can clear `Waiting_for_Next_Invoice__c`, and there is no self-service re-attach. Telling someone to do something they have no permission to do wastes a round trip.
- **Surface the known defect** where the file records one. A reply that reads cleaner than reality gets reopened.
- **Where a file carries a `> **Verified <date>:**` note, that note wins** over the sentence above it.
