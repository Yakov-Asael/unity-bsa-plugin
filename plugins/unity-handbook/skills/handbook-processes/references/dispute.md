# Dispute

> Source: BSA Process Handbook, tab "Dispute". Verbatim.

**Dispute**

**Process:** Dispute · **Objects:** Dispute__c, Dispute_Line__c, Dispute_Freeze__c · **Date:** 9 August 2026 · **Business owner:** Bar Damti (Business Operations Manager), with Tal Rahamim · **Technical owner:** Dror Diamant → Noam Abutbul

# 1. What this process does

A Dispute is the only supported way to change the amount on an invoice (advertiser) or a bill (publisher) after it has been created. An account manager raises one when a client is over-billed, when fraud is confirmed, when a rebate or incentive is owed, or when Unity has to claw revenue back from a publisher. It carries an amount, an activity period and a reason; it is approved through a tiered chain that reflects how much money is moving; and only then is it applied to a real invoice or bill. Everything finance reconciles at month end — the BI dispute lines, the credit notes, the SOX approval evidence — comes out of this process.

**Lifecycle**

**1.** An AM creates the dispute from an account, from the invoice/bill management page or automatically from a deal. Type is Deduction or Positive Discrepancy; Reason for Dispute comes from a Division-specific list.

**2.** Dispute_Set_dispute_approvers stamps the approver fields from the Approver Matrix and sets ApprovalStatus__c = "Pending Approval". Small amounts skip straight to "Approved by business".

**3.** The Dispute Approval Process runs up to four sequential steps. Each step is skipped when its approver field is blank, so most disputes clear in two or three.

**4.** On final approval ApprovalStatus__c becomes "Approved by business" and the Attach Invoice / Attach Bill button appears on the record.

**5.** The AM attaches an invoice or bill — or ticks "waiting for the next one". Dispute_Deduct_Invoice_Subflow moves the document amount, writes the invoice/bill line, and closes the dispute.

**6.** If the bill/invoice was already approved, the dispute goes instead to the Dispute finance approval process so finance can credit and reissue. Only then does Status__c become "Closed".

**The one thing a newcomer gets wrong:** never set the Invoice or Bill lookup by editing the field. Use the Attach button. Editing the lookup directly skips the deduction automation entirely — the invoice is never changed and the dispute sits at "Open" forever, looking attached.

# 2. Where records are created, and how they reach their target

| **Entry point** | **How it works and what to know** |
|---|---|
| Account → Create Dispute / Create Dispute OW / Create Dispute pub | The main manual path. Quick actions on Account launch the Dispute_Create_New_Dispute_From_Account screen flow. The record type follows the account's Department — Demand Dispute for advertisers, Supply Dispute for publishers — and two validation rules enforce it. |
| Invoice or bill management page → Create Dispute | Creates the dispute pre-filled from the document, with Created_from_the_new_process__c = TRUE. Any creation path that does not set that flag is blocked (§4). The invoice or bill must be recalled first if it is already submitted. |
| Fraud case → automatic | Fraud claims and disputes must be linked to a fraud case, and one case links to exactly one dispute — a second has to be handled manually. Apex: Fraud_DisputeCreateBatch, Fraud_DisputeInvoiceJob, Fraud_DisputeBillJob. |
| Opportunity → Create Disputes (supply and demand deals) | Supply incentive payments come through disputes rather than Deal Payments. One $0 dispute is created per payment period; the count comes from Supply_Deal_Num_of_disputes__mdt (§7). |
| Aura invoice under $50 → automatic | Dispute_Create_Dispute_when_Aura_invoice_50 creates a dispute that zeroes the invoice, so tiny Aura invoices are never issued. |
| SuperSonic platform event | SuperSonic_Disputes__e feeds Dispute_PE_Create_SuperSonic_Disputes. These get their own record type and their own single-step approval process (§5). |
| Import Disputes (web link) and Adjustments → Create Dispute | Bulk and adjustment paths used by Business Operations. Imported records still run every record-triggered flow, so a large import fires the full automation chain. |

**How the dispute reaches the invoice or bill**

  - > The Attach Invoice / Attach Bill button appears on the dispute only when ApprovalStatus__c = "Approved by business" and no bill/invoice is attached yet. The AM does this themselves.

  - > If the chosen invoice or bill is still pending approval, the amount is changed directly and the dispute closes.

  - > If it is already approved but not paid in full, the dispute is submitted to finance instead (Waiting_for_finance_approval__c = TRUE) so finance can credit and reissue. The AM cannot complete this alone.

  - > If it is already paid, it cannot be modified at all — the dispute has to wait for the next cycle or be cancelled.

  - > Ticking "waiting for next invoice / next bill" defers attachment to the next generated invoice/bill. The AM cannot untick it afterwards.

# 3. The flows — what each does and what triggers it

Twenty-eight active flows. Three do most of the work and cause most of the incidents: Dispute_Set_dispute_approvers (who approves), Dispute_Attach_Invoice (the screen the AM uses) and Dispute_remove_invoice_when_rejected_by_finance (everything that happens after approval).

| **Flow** | **Trigger** | **What it does** |
|---|---|---|
| **CREATION** | | |
| Dispute_Create_New_Dispute_From_Account ° | Screen — Account "Create Dispute" buttons | When an AM launches it from an account, it collects amount, activity period, Type and Reason for Dispute and creates the Dispute__c with the record type matching the account Department. |
| Deal_Create_Supply_Deal_Dispute ° | Screen — Opportunity "Create Disputes" | When a supply deal with an incentive is closed, and the user hits the create dispute button, it creates one $0 dispute per payment period. |
| Demand_Deal_Auto_Dispute_creation ° | Opportunity, after save | When a demand deal with a rebate or UA Bonus is confirmed, it creates the matching incentive disputes. |
| Dispute_Create_Dispute_when_Aura_invoice_50 ° | Invoice, after save | When an Aura invoice comes out under $50, it creates a dispute that zeroes it rather than billing the client. |
| Dispute_PE_Create_SuperSonic_Disputes ° | Platform event — SuperSonic Disputes | When a SuperSonic dispute event arrives, it creates the dispute on the SuperSonic record type, which routes it to the separate single-step approval process (§5). |
| Dispute_Duplicate_records | Dispute, before save on create | When a new dispute matches an existing one on account, period and type, it sets Duplicate_Exist__c = TRUE and stamps Duplicate_Dispute__c with the other record's Long_Dispute_ID__c. It warns — it does not block. |
| Dispute_Create_Freeze_Object | Dispute, after save on create, or when Deducted_Amount__c / Send_to_BI__c / cancellation changes | Creates the Dispute_Line__c rows and the Dispute_Freeze__c record, rolls the amount into Activity_Period_Revenue__c and Activity_Period_Payout__c, and flags Unapproved_Dispute_Attached__c on the invoice or bill above $500 (AppCloud) / $1,000. Widest blast radius here — it owns the BI dispute lines finance reconciles against. |
| **APPROVAL** | | |
| Dispute_Set_dispute_approvers | Dispute, after save on create and on Deducted_Amount__c change (not SuperSonic, not delta disputes) | Stamps Demand_Dispute_Approver__c and Dispute_Approver_2/3/4__c from the Approver Matrix and sets ApprovalStatus__c = "Pending Approval"; adds approver 3 when the dispute is ≥70% of account revenue and over 90 days old, or >20% of a publisher's monthly payout; instead sets "Approved by business" for advertiser deductions under $1,000 and positive discrepancies under $10,000. Behind almost every "approvers are blank" ticket (§9). |
| Dispute_Set_approved_by_business_if_amount_less_than_1000 | Dispute, after save on create — Publisher, automatic, Clawback, Deduction, under $1,000, created by svc-ba-integration | Sets Approved_Automatically__c = TRUE on small automatic supply clawbacks so they bypass the chain, and writes an ErrorObject__c record on failure. Label says "Auto Approve Clawback Async" — the API name is misleading. |
| Dispute_Block_submitting_UA_Bonus_and_Incentives_without_attachment | Dispute, after save when ApprovalStatus__c changes — UA Bonus, Adv Incentive Plan, Make Good, or any reason at ≥$10,000 | Checks that a file is attached and that Deal__c is populated before an incentive dispute can move on. |
| Dispute_Mass_approve_fraud_disputes | Screen — needs Supply_Fraud_Dispute_Approver_1 or _2 permission | Lets an approver tick a list of fraud disputes and publishes one approval platform event per record. Fifty at a time maximum, and the rows clear over several minutes — reselecting the same disputes double-submits them. |
| Dispute_PE_Mass_Approve_Reject_Submit | Platform event — Approve/Submit/Reject Approval Process | Reads Type__c on the event and either submits the dispute for approval or calls the ResolveApprovalRequest Apex action to approve or reject it. Currently failing with "insufficient access rights on cross-reference id". |
| **ATTACHMENT & DEDUCTION** | | |
| Dispute_Attach_Invoice | Screen — Attach Invoice / Attach Bill buttons on the dispute | Lets the AM pick an existing invoice or bill, or defer to the next one (Waiting_for_Next_Invoice__c / Waiting_For_The_Next_Bill__c); stamps Attach_Timestamp__c and Choosen_Invoice_ID__c, calls the deduct subflow, and for an already-approved document sets FinanceApprover__c and submits for finance approval instead. Most frequent fault: "This record is currently in an approval process." |
| Dispute_Deduct_Invoice_Subflow | Autolaunched subflow — called by Dispute_Attach_Invoice and by the post-approval flow | Moves Invoice__c.Amount_for_Invoice__c or Bill__c.Amount_For_Bill__c by the dispute amount, sets Disputed__c = TRUE and Reason_for_Discrepancy__c, creates the invoice or bill line, spawns a delta dispute when more than $0.50 is left over, and closes the dispute. Remainders under $0.50 are silently dropped. |
| Dispute_remove_invoice_when_rejected_by_finance | Dispute, after save when ApprovalStatus__c, Deducted_Amount__c, Freeze__c or Slack_Approval__c changes | On finance rejection it clears Invoice__c / Bill__c and Waiting_for_finance_approval__c; on business approval it sets FinanceApprover__c and ApprovalStatus__c = "Pending finance approval" and creates the credit bill; on finance approval it closes the dispute. 28 decisions and 17 updates in one flow — the hardest thing here to change safely. |
| Dispute_Update_Bill_Type_and_Activity_Period ° | Screen | Lets finance set Bill_Type__c and the bill activity period on a supply-deal dispute, which the finance step requires before it can be approved. |
| Dispute_Prepare_Adjustments_for_disputes ° | Scheduled | Prepares the Commission_Adjustments__c rows that carry dispute amounts into the commission calculation. |
| **NOTIFICATIONS** | | |
| Dispute_Update_run_notification_flow | Dispute, after save when Approver_Slack_ID__c changes and is not blank | Sets Run_Notification_Flow__c = TRUE. This flag is the only thing that starts a Slack notification — if the approver has no Slack ID, nothing is ever sent. |
| Dispute_Slack_Notifications | Dispute, after save when Run_Notification_Flow__c = TRUE | Slack-DMs the current approver through the Centro app for the pending approval statuses, or the owner when the dispute is "Approved by business" and still has no invoice attached, then sets the flag back to FALSE. |
| Dispute_Send_Slack_Notification_when_dispute_50K_is_approved | Dispute, after save — "Approved by business" and (≥$50,000 or Account_Type__c = Prepayment), excluding SuperSonic and AppCloud | Posts the approval to Slack, and also sends an email when the account is prepayment — because prepay clients need the money funded back to their dashboard, not deducted from an invoice. |
| Dispute_Send_waiting_for_approval_notification | Scheduled daily | Emails the pending approver once Notification_Counter__c reaches 2 on disputes ≥$1,000, or emails the AM to attach an invoice or bill once Attach_Invoice_Notification_Counter__c reaches 2. Skips frozen disputes, SuperSonic, and inactive users. |
| Dispute_Send_Monthly_Open_Disputes_Notification ° | Scheduled monthly | Builds the monthly list of fully approved disputes with no invoice or bill attached. |
| Dispute_PE_Send_Attach_Monthly_Notification ° | Platform event — Unattached Disputes Notification | Send that monthly list to account managers. |
| **STATE & MAINTENANCE** | | |
| Dispute_Freeze_Dispute | Screen — Freeze / Unfreeze buttons, Business Operations only | Toggles Dispute_Freeze__c.Freeze__c. A frozen dispute cannot be attached to an invoice and drops out of the reminder emails; the user sees a message telling them to contact Business Operations. |
| Dispute_Cancel_Dispute | Screen — Cancel Dispute button | Sets Status__c = "Canceled" and stamps Cancelled_Timestamp__c. This is the preferred end state for an approved dispute that is no longer needed — do not attach it to an invoice just to close it. |
| Dispute_Update_revenue_on_the_first | Scheduled daily, acts only when Day_Today__c = 1 and the dispute was created last month | Recalculates last month's disputes into Activity_Period_Revenue__c and Activity_Period_Payout__c and the Banner / IS / OW splits, so the monthly revenue figure reflects late disputes. |

*° Live in the org but absent from the metadata repo snapshot — description taken from the flow label and from build documents; confirm in Flow Builder.*

**Live issue:** PE_Deduct_Add_dispute_to_invoice_or_bill — the flow that applies disputes flagged "waiting for next invoice/bill" — is INACTIVE in the org. Confirm this is intentional before promising anyone their dispute will attach next cycle.

> **Verified 17 August 2026:** the flow is indeed inactive (`FlowDefinitionView.IsActive = false`), but it is **not the only path** — two scheduled Apex jobs do this work and are live (`State = WAITING`), both in Asia/Jerusalem:
>
> | Job | Cron | Runs |
> |---|---|---|
> | `Attach to next invoice` | `0 0 20 2 */1 ?` | 2nd of each month, 20:00 |
> | `Attach to next bill` | `0 0 20 4 */1 ?` | 4th of each month, 20:00 |
>
> Both fired as expected in August 2026 (2 Aug and 4 Aug). So attachment on the next cycle *does* happen on a schedule, and the warning above overstates the problem — treat the inactive flow as one disabled route rather than as "nothing will attach". Confirm the current schedule with `handbook-code-lookup` before quoting these dates to anyone, since cron entries are org configuration and can be paused or changed without a code change.

# 4. Validation rules — what blocks users and why

| **Rule** | **What it blocks** | **Error the user sees** | **Why it exists** |
|---|---|---|---|
| **VALIDATION RULES ON Dispute__c — 8 active of 34. Change these in Setup → Object Manager → Dispute → Validation Rules.** | | | |
| Block_Creation_Not_From_Screen | Creating a dispute anywhere except the supported screen flows | "You can't create a dispute from here. Please create the dispute from the account." | Every downstream flow depends on fields only the screen sets. Checks Created_from_the_new_process__c. |
| Validate_Channel | A Channel that does not match the account's Division | "Channel is wrong. For iAds account please choose Video or Platform. For Tapjoy accounts, please choose OW." | Channel drives revenue reporting. This rule is what is currently failing automatic supply-deal dispute creation (§3). |
| Cant_Create_Dispute_for_Publishers | A Demand Dispute record type on a publisher account | "Please choose a demand account." | The record type decides the approval ladder and whether the dispute hits an invoice or a bill. |
| Cant_Create_Dispute_for_Advertiser | A Supply Dispute record type on an advertiser account | "Please choose a supply account." | Same reason, opposite direction. |
| Amount_must_be_positive | A negative Deducted_Amount__c | "Amount must be positive" | Direction is carried by Type__c — Deduction vs Positive Discrepancy — never by the sign of the amount. |
| Block_Send_to_bi_if_month_BI_is_blank | Ticking Send to BI while Month_BI__c is empty | "Month (BI) is missing. You can't send this dispute to BI" | BI reconciles on the activity month. A dispute line with no month is the known cause of the recurring BI data-compare failure. |
| Cant_Change_Send_to_bi_when_supply_deal | Send to BI or Send to Finance on a Supply Deal Incentives dispute | "When reason for dispute is Supply Deal Incentives, dispute cannot be sent to BI and Finance." | Supply deal incentives are settled through the bill, not through the BI/finance extract. |
| **ENFORCED IN FLOW, NOT AS A VALIDATION RULE — change these in Flow Builder, not in Setup** | | | |
| Attachment required for incentive disputes | Moving a UA Bonus, Adv Incentive Plan or Make Good dispute — or any dispute ≥$10,000 — without a file attached | | SOX: any dispute over $10,000 needs proof attached. Owned by Dispute_Block_submitting_UA_Bonus_and_Incentives_without_attachment. |
| Fraud amount must match the fraud case | Attaching a fraud dispute whose amount differs from the case's approved amount | A pop-up on the Attach Invoice screen — users report it firing when the amounts do match | Stops disputes crediting more than the fraud investigation approved. It is not one of the eight active validation rules — verify where it is enforced before changing anything. |
| Freeze blocks attachment | Attaching an invoice to a frozen dispute | "This dispute is under 'Freeze mode'. You cannot attach an invoice until we receive more information about this dispute. For more information, please contact Business Operations team." | Lets Business Operations hold a disputed amount while it is investigated. |

*26 of the 34 validation rules on Dispute__c are inactive, including Finance_can_approve_only_after_credit and Finance_can_approve_only_afterbillcredit, which the build documents describe as live controls. Treat those documents as out of date on this point — the org is authoritative.*

# 5. Approval processes — what exists and what triggers each

| **Approval process** | **Object / record type** | **What triggers entry** | **Who approves** | **Approve vs reject** |
|---|---|---|---|---|
| Dispute Approval Process | Dispute__c — every record type except SuperSonic | ApprovalStatus__c = "Pending Approval", set by Dispute_Set_dispute_approvers | 4 sequential steps reading user fields: Demand_Dispute_Approver__c → Dispute_Approver_2__c (skipped if blank or the same person as approver 1) → Dispute_Approver_3__c, where Adi Erdan, Bar Damti and Tal Rahamim can also approve → _4. Every step after the first is skipped when its field is blank. | Approve: ApprovalStatus__c = "Approved by business", approver ID cleared, approval timestamp set, attach and Slack notifications armed. Reject: status set to rejected, dispute closed, "dispute was rejected by business" email sent. |
| Dispute finance approval | Dispute__c — any record type | Waiting_for_finance_approval__c = TRUE, set when the dispute is attached to an already-approved invoice or bill | One step: FinanceApprover__c, resolved from Disptue_Finance_Approver_For_Credit__mdt by Division + Department (§7). | Approve: dispute closed and finance status updated. Reject: status set back to rejected and the post-approval flow clears the invoice or bill from the dispute. |
| SuperSonic Disputes Approval Process | Dispute__c — SuperSonic record type only | RecordType = SuperSonic AND ApprovalStatus__c = "Pending Approval" | One step: Demand_Dispute_Approver__c. | Approve: approval timestamp set and status moved to approved by dispute approver. Reject: closed and rejected. |

**Mutually exclusive:** the main process explicitly excludes RecordType = SuperSonic and the SuperSonic process explicitly requires it. Editing either entry criterion silently pushes SuperSonic disputes into the six-step chain, or leaves them with no process at all.

**Recall and re-submission:** all three allow recall. Recalling the main process sets the status back to Pending; recalling finance approval sets Waiting_for_finance_approval__c back to TRUE. A user can only recall while the dispute is genuinely sitting with an approver — an auto-approved dispute never entered a process, so there is nothing to recall. Editing Deducted_Amount__c after approval re-runs Dispute_Set_dispute_approvers and re-stamps the approvers from scratch.

# 6. The approver matrix

Approvers are stamped onto the record when the dispute is created — and re-stamped when the amount changes — not resolved live at approval time. That single fact explains most approval bugs. If the matrix changes, or an approver leaves the company, existing disputes keep the old approver and have to be repaired by hand, one record at a time. The source of truth is the Approver_Matrix records in Salesforce, keyed on Dispute Type × Division × Department × Team × amount level. The business edits a Google Sheet and it is uploaded from there; the amount level also exists as Dispute_Amount_Level__mdt, 96 records.

| **Scope (Dispute Type · Division · Department)** | **Amount band floors** |
|---|---|
| Deduction · MobileCore, Tapjoy, UnityAds · Advertiser | 1,000 → 3,000 → 10,000 → 50,000 |
| Deduction · MobileCore, Tapjoy, UnityAds · Publisher | 0 → 3,000 → 10,000 → 50,000 |
| Deduction · Aura and AppCloud · Advertiser | 500 → 3,000 → 5,000 → 50,000 |
| Deduction · Aura and AppCloud · Publisher | 500 → 3,000 |
| Positive Discrepancy · Tapjoy, Brands | 10,000 → 50,000 → 100,000 |
| CTV · Other | 1,000 → 3,000 → 10,000 → 50,000 → 100,000 |

**The chain:** Team Leader → Senior Manager → Business Operations → Finance. No currency is stated anywhere in the matrix; amounts are read as USD by convention — verify.

**Exceptions that override the normal path**

  - > Advertiser deductions under $1,000 and positive discrepancies under $10,000 are set to "Approved by business" at creation. No approver is ever assigned — and nothing can be recalled.

  - > Publisher clawbacks under $1,000 for SMB accounts are auto-approved by a separate flow.

  - > A dispute worth ≥70% of the account's revenue and over 90 days old, or >20% of a publisher's monthly payout, adds Business Operations as approver 1 or 3.

  - > Reason = Incident Relevant Rebate routes to a fixed approver whose user ID is hardcoded in Dispute_Set_dispute_approvers, regardless of amount.

  - > The credit finance approver is not part of the tiered matrix. It comes from Disptue_Finance_Approver_For_Credit__mdt, keyed on Division + Department, with a DEFAULT fallback row.

# 7. Other mappings in the process

| **Source** | **Target** | **When and why it matters** |
|---|---|---|
| Reason_For_Dispute_Mapping__mdt — 167 records | Which Reason for Dispute values appear for a Division + Department | A missing row means the AM simply cannot pick the reason they need. Two label/API mismatches will trip you up when reading data: "System Over Delivery" is API "Over Delivery", and "Test" is API "Free Test". |
| Dispute_Amount_Level__mdt — 96 records | The amount bands used to select an approver matrix row | Change a band and existing disputes are unaffected — they keep the approvers stamped at creation. |
| Disptue_Finance_Approver_For_Credit__mdt — 11 records | Division + Department → FinanceApprover__c | A wrong finance approver almost always means a missing row here, not a matrix problem. Note the typo in the object name — it is "Disptue", not "Dispute". |
| Supply_Deal_Num_of_disputes__mdt — 8 records | Incentive payment frequency → how many $0 disputes get created | Monthly = 1, Quarterly = 3, Half Yearly = 6, Yearly = 12; one-time payments create a single dispute. |
| Dispute → Dispute_Line__c | One line per activity month, keyed on Month_BI__c | BI reconciles on the line, not the header. Editing the amount on the header without updating the line is the documented cause of the recurring dispute-line vs data-warehouse mismatch. |

# 8. Notifications

| **Notification** | **Trigger** | **Recipients** | **Channel** |
|---|---|---|---|
| Approval request | Dispute enters any approval step | Current approver | Email — "New dispute for `<Account>` is waiting for your approval" |
| Slack approval DM | Approver_Slack_ID__c populated → Run_Notification_Flow__c = TRUE | Current approver | Slack, via the Centro app (approve directly from Slack) |
| Approved — attach an invoice | Final business approval | Creator and account manager | Email — "Dispute for `<Account>` has been approved and you can attach an invoice" |
| Rejected by business | Final rejection on the main process | Creator | Email alert dispute_was_rejected_by_business |
| Daily approval reminder | Scheduled flow, Notification_Counter__c = 2, amount ≥ $1,000, not frozen | Pending approver | Email |
| Attach reminder | Attach_Invoice_Notification_Counter__c = 2, approved with nothing attached | Owner / account manager | Email |
| Monthly unattached-dispute list | Scheduled flow → Unattached Disputes Notification platform event | Account managers | Email — currently sending to 0 recipients |
| Large or prepayment approval | "Approved by business" and ≥ $50,000, or Account_Type__c = Prepayment (excludes SuperSonic and AppCloud) | Business Operations | Slack, plus email when the account is prepayment |
| Freeze / unfreeze | Freeze__c toggled | Creator and account manager | Email — "Dispute for X was freezed by the Business Operations Team" |

# 9. FAQ

**Check these five first:** (1) Is ApprovalStatus__c exactly "Approved by business"? (2) Are the approver fields populated, and are those users still active? (3) Is Freeze__c TRUE? (4) Is the invoice or bill already approved, or already paid? (5) Is Enable_Dispute_Creation__mdt set to "Yes"?

| **Symptom, in the user's words** | **Cause and fix** |
|---|---|
| "I just finished the dispute approving. But I can't attach it into the invoice — I don't see the Attach dispute button." | The button only shows when ApprovalStatus__c = "Approved by business" and nothing is attached yet. Check the approval actually finished — the email says "step 3 of 6", so a partly-approved dispute looks approved to the user. If someone set the Bill or Invoice lookup by editing the field instead of using the button, the deduction never ran: clear the lookup and re-attach through the button. |
| "Dispute is not showing on invoice despite being approved and attached." | The deduct subflow failed after the attach. Check the flow fault emails for Dispute_Attach_Invoice and Dispute_Deduct_Invoice_Subflow — the two live failures are "This record is currently in an approval process" and a restricted-picklist error on Reason for Discrepancy. Clear the lookup and attach again to re-run it. |
| "I cannot submit the dispute because I am missing approver" / "Dispute approvers blank." | Dispute_Set_dispute_approvers found no Approver Matrix row for that Division / Department / Team / amount, or the amount is $0. Ask Bar Damti to add the matrix row, then nudge Deducted_Amount__c by a cent and back to force a re-stamp (§6). |
| "Is this because Bryan Merlos is attached to these accounts? For when employees leave, can we assign their accounts to their manager?" | Approvers are stamped at creation, so a leaver stays on every dispute raised before they left (§6). Reassign the approver field on the record for an immediate fix; update the matrix for new disputes. Existing records are never retro-updated. |
| "Now it says submit for approval, but that no approval process was found." | The record type or ApprovalStatus__c does not match any entry criterion in §5. SuperSonic disputes must be on the SuperSonic process; everything else needs ApprovalStatus__c = "Pending Approval". The same error on a bill means Send_Integration_Fee_Bill_for_approval found no bill approver. |
| "Because the amount was under the threshold, it was auto-approved by the system. Now she is unable to recall or modify the case." | Under the auto-approval thresholds no approval process ever started, so there is nothing to recall (§6). Business Operations has to change the status directly or cancel the dispute and raise a new one. |
| "I've attached to the wrong invoice — seems like I'm not able to re-attach to any invoice now." | There is no self-service re-attach. Raise a ticket with /centro gtm; the fix is a manual back-end change. If the invoice has already been paid it cannot be modified at all — the dispute has to go to the next cycle or be cancelled. |
| "I need to recall and attach this dispute to the Sep invoice. I cannot untick 'waiting for next invoice' from my side." | Only Business Operations or the SFDC team can clear Waiting_for_Next_Invoice__c. Before promising it will attach next cycle, check that PE_Deduct_Add_dispute_to_invoice_or_bill is active — it is not (§3). |
| "I'm trying to create a dispute but got the error message says blocked by finance team." | Block_Dispute_Creation (§4). Creation is closed during the monthly financial close, typically the first 3–5 days. Bar Damti reopens it through the Dispute - Enable creation screen flow. |
| "When I click the attach invoice button, this pop-up appeared. But I'm sure the dispute amount matches the case result." | The fraud amount check firing as a false positive. It is not one of the eight active validation rules — verify where it is enforced before changing anything (§4). Historically the SFDC team has repaired the record by hand so the AM can attach. |
| "Change Reason of Dispute" / "Change of Dispute Type." | Editing the reason after creation does not re-run the reason mapping or re-stamp the approvers, and if the dispute is already attached the invoice line description is already written. Nudge Deducted_Amount__c to force the approver re-stamp; ask finance to reissue if the customer-facing text is wrong. |
| "Delete $0 disputes" / "bulk close disputes as Cancelled" / "remove useless dispute." | Use the Cancel Dispute button — Status__c = "Canceled" — not deletion. Where a dispute must stay for audit but should not move money, Business Operations sets the amount to zero; the team calls this "zeroing it". |
| "Channel is wrong. For iAds account please choose Video or Platform." | Validate_Channel (§4). Tapjoy accounts take OW only; iAds accounts take Video or Platform. This rule is currently blocking automatic supply-deal dispute creation, so expect it on records nobody created by hand. |
| "I'm getting an error message: No invoice approver defined for this invoice" / "still showing an error for not being linked to finance system." | Not a dispute problem. The account is not linked in the finance system, so the invoice has no approver. Ask the finance-systems team to link the account, then resubmit the invoice; the dispute will then attach normally. |
| "The clawback process was automated through disputes. Over the past 3 months we consistently receive 120–150 disputes assigned to my team." | Approved clawbacks auto-attach to an open bill only for self-served accounts. Everything else lands on AP manually, and it lands during the AP close. Open escalation with no owner assigned — the incoming owner should pick this up. |

*Escalation: approver matrix and dispute policy go to Bar Damti or Tal Rahamim. Salesforce configuration, flow faults and datafixes go to Yakov Asael. Users raise everything with /centro gtm in Slack; day to day the process lives in #ask-grow-salesops and #gps_ams_finance.*

# 10. Dashboards and reports

| **Dashboard** | **Folder** | **Who uses it** | **Still trustworthy?** |
|---|---|---|---|
| [Chief Financial Dashboard](https://ironsrc.lightning.force.com/analytics/dashboard/0FKQv0000001QLROA2) | Dispute | Management | Yes — maintained |
| [Disputes Dashboard](https://ironsrc.lightning.force.com/lightning/r/Dashboard/01Z5p0000015JjwEAE/view) | Dispute | Business Operations — the only dashboard still maintained | Yes — maintained |
| [Disputes Dashboard - Finance](https://ironsrc.lightning.force.com/lightning/r/Dashboard/01Z5p0000015JmWEAU/view) | Dispute | Finance | Stale — verify before trusting |
| [TL Dispute Dashboard](https://ironsrc.lightning.force.com/lightning/r/Dashboard/01Z5p0000015JwREAU/view) | Dispute | Team leads | Stale — verify before trusting |
| **Report** | **Folder** | **What it is for** | |
| **DAILY / OPERATIONAL MONITORING** | | | |
| [Dispute Approvers - Monitor](https://ironsrc.lightning.force.com/lightning/r/Report/00O5p000007kxnKEAQ/view) | Dispute - New | Scheduled and emailed daily at 09:00 — deduction disputes ≥$1,000 and positive discrepancies ≥$10,000 with approver 1 blank. This is the early-warning system for the "approvers are blank" problem. Currently goes to Dror only. | |
| [Disputes pending approval](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000AZddRMAT/view) | Clean up and ongoing review | Everything sitting in an approval step right now. | |
| [My Pending Disputes](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000FGIErMAP/view) | Public Reports | What an individual approver owes — the report to send someone who says they never got the email. | |
| **AUDIT & SOX** | | | |
| [Dispute Approver Matirx](https://ironsrc.lightning.force.com/lightning/r/Report/00O5p000007hbNvEAI/view) | Private Reports | The live Approver_Matrix records — export this for the quarterly SOX control (spelling of the report name is as-is in the org). | |

*"Dispute - New" is the standard operational pack; "Financial closing reports", "Clean up and ongoing review" and "SOX" are the other real units of ownership. Dispute Approvers - Monitor is the only scheduled, emailed report in the set and it is subscribed to Dror alone — reassign the subscription at handover or the alerting stops silently.*

# 11. Related documents

| **Document** | **Type** | **Open this when…** | **Status** |
|---|---|---|---|
| **REQUIREMENTS & DESIGN** | | | |
| [Aura Dispute PRD](https://docs.google.com/document/d/1QTNWyPaHx2B3Tx0xZJEPwp1kwnK81h4InPSy8hWOSag/edit) | Doc | A dispute was created with the wrong record type, account or division — has the button-visibility logic and the auto-populate field map including record type IDs. | Draft — never signed off, but partly built |
| [Supply Deal Dispute PRD](https://docs.google.com/document/d/1meAuE2t3af76esaKk1AU-gnVNfLOuXlngVa36bOMDZM/edit) | Doc | A dispute was auto-created from a deal and the count, activity period or amount looks wrong. | Draft — never signed off; H1 mis-titled "Aura Dispute" |
| [Supply Dispute DD](https://docs.google.com/document/d/1PXIDaWknkXO1wjv97n-c_nfz4Fexl88RBTJNchbJNwk/edit) | Doc | Anything on the supply/bill side: clawback auto-creation, commission adjustments, bill-field blocking. | Current for supply; appended Tapjoy section is draft |
| [Attach dispute to next invoice / bill batch](https://docs.google.com/document/d/123UwwH-GqFk5osbfpktd1d0vkS6dYOJkmiXDb4PM7eU/edit) | Doc | A "waiting for next invoice" dispute did not attach, or an invoice was over-deducted — has the exact batch filters and run times. | Current |
| [Dispute DD](https://docs.google.com/spreadsheets/d/1NF_OrDqblkmPY9dN-HhQcqe9twrYbjiuW4mKlx53b2U/edit) | Sheet | You need the original field list or the canonical ApprovalStatus picklist values, which no later document restates. | Obsolete — its approver tiers are Credit Check, not dispute; note a second file shares this title |
| **MATRICES & MAPPINGS** | | | |
| [Dispute Approver Matrix - July 2026](https://docs.google.com/spreadsheets/d/1bkM0wnES-fPoHieHaggO5vjtmgWuJ2CKf20IH54dBCg/edit) | Sheet | You need to answer "who approves at what amount" — a direct export of the live records, and authoritative on thresholds. | Current |
| **BUILD & IMPLEMENTATION** | | | |
| [Dispute Process Modification and New Implementation](https://docs.google.com/spreadsheets/d/1jnvD_bCBDDt9Jo_PTsEXbPCS6hJJiEwigOKRMGdOQSw/edit) | Sheet | A supply dispute is blocked and you need the validation rule name — the best list of named rules, plus 20 QA scenarios. | Current for the supply go-live; some rules it names are now inactive |
| [Supply deal disputes implementation file](https://docs.google.com/spreadsheets/d/1ru7_riGiYDV1Q8n4igQ6YtNz__AtCJ-UR956ShDDfew/edit) | Sheet | You need the supply-deal component list and the four legacy deal-payment flows that were cancelled. | Current |
| [SuperSonic Disputes Implementation File](https://docs.google.com/spreadsheets/d/1EAMMS8rZEwudgeHbN9WlzoXTiyeTFdUazsMjrS4w0BU/edit) | Sheet | A SuperSonic dispute misbehaves — record type, separate approval process, platform event and its fields. | Current — rows 14–40 unmarked |
| [Dispute Slack Notifications](https://docs.google.com/spreadsheets/d/13OjZqXt-6O2FqWyZFioRUNTkQk-94DXlvrbHFahdC2k/edit) | Sheet | A Slack approval notification did not fire — names the four components including Approver_Slack_ID__c. | Current |
| [Create Dispute from invoice/bill management comments](https://docs.google.com/spreadsheets/d/1yflZ0rN8XZCxPTYPBq-Z0zKX1ocGWNJ1ROU21oyBGE0/edit) | Sheet | The create-dispute screen behaves oddly for a non-Aura division — 10 logged defects, all fixed. | Current |
| **TRAINING & ROLLOUT** | | | |
| [Dispute - Invoice Deduction training](https://docs.google.com/presentation/d/1cZEyh5pe6hO0d7oZJiN9dzsuZt7ZR3S70srLARMrCkI/edit) | Slides | You need to explain the process to a business user — the only end-user asset that exists. | Superseded in content but still the only training deck |
| **BACKLOG** | | | |
| [Dispute - Wish list](https://docs.google.com/spreadsheets/d/1RHlShi-1NyXC5fFN6whpcbvrXt0iEfvKfORfJ2r2F1Q/edit?gid=644285792#gid=644285792) | Sheet | | Current |
