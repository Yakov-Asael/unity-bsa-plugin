# Bills/Invoice Sync

> Source: BSA Process Handbook, tab "Bills/Invoice Sync". Verbatim.

**Invoice and Bill**

**What this is:** a list of the problems that actually happen with invoices and bills and what to do about each one, plus a full map of the Invoice Management and Bill Management screens · **Covers:** Invoice__c, Invoice_Line__c, Bill__c, Bill_Line__c, the two management screens and their integrations · **Author:** Dror Diamant (outgoing) → Yakov Asael

*§1 the five causes behind most of it · §2–8 the problem list, by area · §9–13 the Invoice and Bill Management map · §14 what is still open · §15 tools · §16 who to ask.*

**Read this first.** Almost none of these were bugs in the billing code. The overwhelming majority trace back to five things — a picklist value that does not exist, a person who has left, an account that was never synced, upstream BI data that is wrong, and a field on the Account quietly changing behaviour. Check those five before you debug a batch class. Green in the Status column means solved for good; red means it will happen again.

# 1. The five causes behind almost everything

| **#** | **Cause** | **How it shows up, and what to check first** |
|---|---|---|
| 1 | A restricted picklist is missing a value | A valid business value arrives from BI or from a dispute, the picklist rejects it, and the record — or just its lines — fails silently. Read the exact value out of the error and check whether it exists on the field. Seen on Invoice_Line__c.db__c, Invoice__c.Reason_for_Discrepancy__c, Bill__c.Re__c, Purchase_Type__c and ClientTier__c. |
| 2 | Somebody left the company | Approvers, account managers and matrix rows all resolve to named users. A deactivated user gives you "No invoice approver defined for this invoice.", a missing Submit button, or a dispute with no approver. Check the AM and the matrix row are active users before anything else. |
| 3 | The Account was never synced to the finance system | The invoice or bill approves happily in Salesforce and then never appears in Workday. Only accounts with open transactions were migrated from NetSuite, so any older or newly active account is a candidate. Sync the Account; the bills follow. |
| 4 | BI data is wrong, missing, or was restated after the fact | Salesforce is downstream. Critically: recreating the record does not help, because it re-reads the same table. Fix the source, then refresh. Never delete and recreate. |
| 5 | A field on the Account is silently driving it | Invoice view type (Detailed or Summary), "Invoiced with", "One invoice per", the DSP Seat name, billing country. None announce themselves, all change what gets produced, and one wrong value repeats every cycle until the account is fixed. |

**The pattern worth internalising:** nearly everything below recurred. Fixing the record in front of you takes ten minutes; fixing the account setting or the picklist behind it is what stops it coming back next month.

# 2. Problems — the invoice or bill was never created

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| An invoice exists but has no lines, and the load errored on a picklist | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST on db__c for a division value that does not exist. Someone switched the account from Summary to Detailed, and Detailed had never been produced for that division. | Add the value to Invoice_Line__c.db__c, then re-run the load for that division. Check the account's breakdown setting — if the switch to Detailed was accidental, put it back. | Solved. Recurs for the next division switched to Detailed. |
| An invoice was created as Detailed with no lines anywhere | The line rows were simply absent from the BigQuery lines table. Nothing to load. | Correct the invoice manually. No line-level repair is possible unless BI backfills the source. | Worked around. A report monitors the volume; nothing prevents it. |
| One particular account never gets an invoice created | Its BI opportunity key aggregates several opportunities and exceeds the field length, so the row fails on load every cycle. | Create the invoice by hand each cycle from the demand advertisers table. Real fix: widen the field or split the key. | Never fixed. A standing monthly manual task. |
| No bills were created for a whole division | Either those accounts have never produced bills — correct behaviour, nothing to create — or the creation batch was not run for that division. | Establish which. If it is the batch, run BillCreationBatch scoped by division, not by account Ids. Signature in §15. | Solved. |
| A bill was created with a negative or zero amount | BI pushes negative and zero payout rows; the creation code does not filter them. | Delete the bill by hand. Durable options: add an amount-greater-than-zero check, or have BI stop sending them. | Worked around only. |

# 3. Problems — the amount is wrong

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| The header amount does not match the sum of the lines | Duplicate Invoice_Line__c rows from a re-run, or a roll-up that did not recalculate because the retry batch was in conflict. | Delete the duplicate line rows and let the roll-up re-run once the conflict clears. | Solved. |
| Every invoice in the monthly run has the wrong amount | The upstream BI tables were wrong. Has happened at P0 across a whole run and again at division scale. | Repair the BI tables, then re-sync amounts rather than recreating invoices. Agencies re-run as a separate pass. Leave the BI total diverging from the approved figure deliberately — it is the evidence that the data streamed in wrong. | Solved each time; a recurring class. Treat any month-wide complaint as a BI question first. |
| Bill amounts are wrong because BI restated after the bills were created | The source table changed after creation. Deleting and recreating does not help — recreation reads the same restated table. | Refresh the existing bills from BI. There is a targeted script — §15. This is the generalisable lesson: refresh, never recreate. | Solved. |
| Invoices were created for secondary accounts that should not be invoiced | A previously fixed defect resurfaced. No data existed for those advertisers in the detailed-app BI table. | Delete the incorrect invoices, keep the correct one. Confirm with BI whether the original fix is still in place. | Recurrence of an old bug. |
| Two disputes on one invoice both come out wrong | The deduction logic does not compose when more than one dispute lands on a single invoice. | Check the arithmetic by hand whenever it happens. No code fix recorded. | Open. |

# 4. Problems — wrong account, subsidiary or address

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| The invoice bills the Brand, but the Agency pays | Structural. Invoices follow the account on the opportunity's BI opportunity, and on GPS the opportunity sits on the Brand. | On the brand account set "Invoiced with" to the agency. On the agency account set "One invoice per" — All for one combined invoice, Account for one per brand. Default is separate. | Per account, prompted by nothing. Keeps recurring on GPS. |
| Two invoices appeared this month instead of one | A trailing space in the DSP Seat name split the account key in two. | Merge the invoices, then remove the space from the DSP Seat setting page. Without the second step it repeats monthly. | Solved if the seat was actually corrected. |
| The Bill-To address on an issued invoice is wrong | The invoice was issued before the billing details were corrected. An issued invoice is not editable in place. | Credit memo to nullify, then reissue with the corrected address. | Solved. |
| Wrong subsidiary and the account manager cannot change it | Set by the Update Subsidiary by Billing Country flow, which has failed where a picklist value it copies from the parent does not exist on the child. | Add the missing picklist value, or stop copying an unmapped parent value. Subsidiary is not AM-editable by design. | Mechanism understood; gaps fixed as they surface. |
| Line items the customer does not recognise | Activity from a related entity consolidated onto the invoice by the one-invoice-per setting. | Set "One invoice per" to Account if the customer needs activity broken out. | Configuration, not a defect. |

# 5. Problems — stuck in approval

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| "No invoice approver defined for this invoice." | The approver resolves from the Account Manager and that user is deactivated. The most-reported invoice error in the whole set. | Three steps in order: reassign the AM on the invoice to an active user, sync the account, then submit. Doing only the first leaves it to fail later at the integration. | Solved every time, never prevented. |
| A dispute or bill has no approver at all | The approver matrix still lists people who have left. One leaver breaks every record resolving to that row. | Remove or replace rows whose approver is inactive, then reassign affected records. A periodic manual reconciliation is the closest thing to a fix. | Recurring. No automated check exists. |
| Approvals go to the wrong first-line approver for a team | The matrix row named the wrong person. | Update the row and manually reassign anything in flight. Tell the team where their approvals have moved. | Solved. |
| Submit for approval is missing, or mass submit fails for everything | Usually the inactive-AM problem again, or the account is not synced to the finance system. On Bill Management, submit is additionally blocked when the account has no finance-system Id — see §11. | Check the AM is active and the account is synced, then submit. | Solved per occurrence. |
| The status was set to Pending but the record is still locked | Somebody edited Status instead of recalling the approval. The approval process is still running. | Recall the approval properly. Never fix approval state by editing the status field. | Solved. |
| Attach Dispute throws an error on an invoice | The invoice is locked because it is in an approval process. The error is not about the dispute. | Recall or wait for the approval, then attach. | Understood; the message is misleading. |

# 6. Problems — approved in Salesforce, never reached Workday

**The best-documented family in the set —** the same root cause recurred four times across five tickets. If an approved invoice has no Workday Id, start with the first row.

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| An approved invoice simply never appears in Workday | The Detailed / Summary view type does not match whether the invoice actually carries line descriptions. Workday declines it silently — no error surfaces in Salesforce. The repeat offender is the default set at account level, which reapplies every cycle. | Flip the view type on the invoice so it matches its content. Then correct the default on the Account — this is the step that kept being skipped, which is why it came back four times. | Fixed per invoice four times; the account default is still the outstanding action. |
| Bills rejected — supplier does not exist in Workday | Only accounts with open transactions were migrated from NetSuite. Any account outside that set has no supplier record. The integration is working; the data is missing. | Sync the Account to Workday, then the bills follow. To re-drive bills that already failed, touch LastModifiedDate. Long term: migrate the remaining accounts. | Worked around repeatedly; migration agreed and not completed. |
| The bill's Workday Id contains a stale NetSuite Id | Migration leftover — the field holds an identifier from the old system so nothing matches. | Clear the Workday Id on the bill and let the account re-sync. | Solved. |
| The sync refuses a bill whose due date precedes the invoice date | Workday will not accept a due date earlier than the document date. | Clear the due date. Verify it actually cleared — in at least one case the first attempt did not take. | Solved, with a verification caveat. |
| The error log points at NetSuite but you are on Workday | The error log template is out of date. The bill balance batch actually calls a Workato recipe. | Read the Workato response, not the log heading. The stale wording should be corrected. | Understood; text still wrong. |
| Paid in Salesforce, still Open in Workday | A reconciliation gap between the two systems. | Corrected manually on the Workday side by AR. | Worked around per record. |

# 7. Problems — disputes, credits and reversals

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| A dispute cannot update the invoice, or cannot create its bill | The dispute reason value does not exist on the target field — Invoice__c.Reason_for_Discrepancy__c in one case, the equivalent on Bill__c in the other. | Add the value to both. Any new dispute reason has to be added in three places: the dispute picklist and both downstream fields. | Remedy known, not recorded as applied. Standing check for any new reason. |
| Approved disputes are sitting unattached | Nothing forces attachment after approval, so they accumulate. An automated reminder chases them. | Attach them manually. They can be re-attached to a different invoice on request. | Managed by nagging. |
| Clawback disputes attach to bills that were already approved | The auto-attach logic does not exclude approved bills. | Handled case by case. No systemic fix recorded. | Open. |
| Disputes reach Finance or Snapsource that should not have | Two causes. Some dispute types must never have send-to-finance set true. Separately, a BI filter used an exact-match exclusion where it needed a prefix match, so values beginning with the excluded string slipped through. | Change the exclusion to a prefix match. Block the send-to-finance flag on the dispute types that must not go. The prefix-match lesson generalises to any exclusion on free-text-ish values. | Filter defect identified precisely. |
| A credit was applied but the downloaded PDF shows the old amount | The document is generated separately from the Salesforce figures. | Reissue the invoice so the PDF regenerates. | Solved. |
| The customer wants a standalone credit memo | Credits are modelled as adjustments against an invoice, not as independent documents. | Use credit-and-reissue. Check the figures by hand — the arithmetic after a partial credit is undefined in the design. | A functional gap, not a defect. |
| An invoice shows Paid In Full when it is not, blocking a dispute | The unapproved-invoices field was driving the paid status incorrectly. | Update the field, then check the balance — it has a knock-on effect on the credit position. | Solved. |
| The Overall Balance double-counts an invoice | A balance calculation defect, observed on Tapjoy. | Investigated; no fix recorded. | Open. |

# 8. Problems — timing and delivery

| **What you see** | **Why it happens** | **What to do** | **Status** |
|---|---|---|---|
| This month's invoices are not available yet | The run is late or a division-level failure held it up. Invoices are expected early in the month and are needed by the fifteenth for commissions, so a few days matters. | Establish whether the run happened at all before investigating records — one missing division looks identical to a whole failed run from the outside. | Managed operationally. |
| One customer never received their invoice | It existed but sat in Pending — the account manager never submitted it. A variant: accounts recently consolidated under one parent changed which invoice the customer should get. | Submit it, then check whether the AM is active. An unsubmitted queue usually means the owner left or changed. | Same leaver pattern as §5. |

# 9. Invoice Management and Bill Management — what they are

Two internal Lightning screens, each its own tab. They are the day-to-day working surface for finance and account managers: a filtered list of invoices or bills, with bulk actions across the selection.

| | **Invoice Management** | **Bill Management** |
|---|---|---|
| What it lists | Invoices — what customers are charged. | Bills — what Unity pays out. |
| Component | invoiceManagement (LWC) | billManagement (LWC) |
| Behind it | InvoiceManagementController and InvoiceManagementRetriever | BillManagementController and BillManagementRetriever |
| Whose accounts | Advertiser accounts only. | Publisher and Affiliate accounts. |
| Primary filter | Division, department and status. | Correction period — the month and year — plus division and status. |

**One naming trap:** the class BillManagementCtrl is not the Bill Management screen. It is the BI-integration engine that creates and updates bills, has no screen methods, and is not referenced by the component. The screen controller is BillManagementController.

# 10. Who can use the screens — it all hangs on one field

**Everything a user can see and do on these two screens is decided by a single picklist on their User record:** FN Role, API name FN_Role__c. There is no permission set, no custom permission and no profile check controlling the screens themselves. If someone's access is wrong, this field is almost always the answer.

The code reads the field and derives up to three internal flags from it. It is a first-match-wins chain, so a user only ever gets one role even if the value contains more than one word.

| **FN Role value** | **Finance role?** | **Management role?** | **Specific flag** | **What it means in practice** |
|---|---|---|---|---|
| Admin | Yes | Yes | isAdmin | Full access. Sees everything in scope, gets every button including Block Subsidiary and Send Confirmation Mail. |
| Bookkeeper | Yes | No | isBookkeeper | The finance approver. The only role that gets Mass Approve & Issue, and only on records already at Pending Finance Approval. |
| Accountant | Yes | No | isAccountant | Finance, without the issue step. |
| TL | No | Yes | isTeamLeader | Team leader. Sees the full list without account-manager narrowing, and can create, submit, approve and reject. |
| AM | No | Yes | isAccountManager | Account manager. Can create and submit, but sees only their own records — see §11. |
| **These three values produce no role at all** | | | | |
| Not Allowed | No | No | — | No buttons. Intended. |
| View only | No | No | — | No buttons. Intended. |
| Finance | No | No | — | Almost certainly a mistake. The code never tests for "Finance" — it tests for Admin, Bookkeeper, Accountant, TL and AM. A user set to Finance behaves exactly like a user with the field left blank: they can open the screen and see nothing useful. |
| (blank) | No | No | — | Same as above. This is the first thing to check when someone says the screen is empty or has no buttons. |

**Two consequences worth knowing.** First, the chain is first-match-wins, so a combined value would only ever resolve to the earliest match — you cannot make someone both an Admin and an AM. Second, the three custom permissions that sound like they belong here — AR permissions, Mass Credit and Finance Supply Deal Dispute — are not consulted by either screen. AR permissions gates dispute pages elsewhere; Mass Credit only hides a button on the Finance home page without removing the underlying capability.

# 11. What each user sees — the record scope

Both controllers run with sharing, so ordinary record sharing applies first. On top of that the screen applies its own scope, and the only role that gets narrowed is the account manager.

| **Role** | **Which records appear** |
|---|---|
| Admin, TL, Bookkeeper, Accountant | Everything in the base scope — all Advertiser invoices, or all Publisher and Affiliate bills — subject to record sharing and to whatever filters are selected. No narrowing by account manager. |
| AM | Narrowed to their own. A record appears if any one of these is true: the Account's Account Manager is them; the record's own Account Manager field is them; the Account Manager is a user who has delegated to them; or, on invoices, the Secondary Advertiser's Account Manager is them. |
| Finance, Not Allowed, View only, blank | The list still renders subject to sharing, but no role flags are set, so the action buttons do not appear. |

**Delegation — the part nobody knows about**

There is a delegation mechanism on the User record: Delegate User. If an account manager sets another user as their delegate, that delegate sees the account manager's invoices and bills on these screens as if they were their own. It is the intended cover-for-holidays mechanism, it is not documented anywhere else, and it is worth knowing when someone can see records you did not expect them to.

# 12. The buttons, and exactly when they appear

**Before the tables — the single most confusing behaviour on both screens.** Every mass action button is hidden while the Status filter is set to "All". Not disabled, hidden. A user who cannot find Mass Approve has almost always left the status filter on All. Ask that before anything else.

**Invoice Management**

| **Button** | **What it does** | **Appears when** |
|---|---|---|
| New | Opens the invoice detail form in a modal. | The user has a management role — Admin, TL or AM. |
| Mass Submit for Approval | Submits the selection, or everything matching the current filter. | Management role, and the Status filter is not "All". |
| Mass Approve | Approves the selection. | Bookkeeper or Admin with the record at an approvable status, or the TL/Accountant branch. Status filter not "All". |
| Mass Reject | Rejects the selection. | Exactly the same conditions as Mass Approve. |
| Mass Approve & Issue | Approves and issues in one step. Always runs as a batch. | Bookkeeper only, and only on records at Pending Finance Approval. Status filter not "All". |
| Export To Excel | Downloads the list as CSV. | Management or finance role. Capped at 10,000 rows. |
| Send Confirmation Mail | Queues the invoices and opens the send-to-customer page. | There are results on screen, and the user is an Admin or on one of three named profiles. This is profile-name string matching rather than a permission — see §13. |
| Block Subsidiary | Opens the subsidiary blocking page. | There are results, and the user is an Admin. |
| Split Invoice | Splits one invoice into several. | Five conditions must all hold: status is Pending, the invoice has no finance-system staging Id, no finance-system Id, its type is Invoice, its amount is above zero, and it is not reopened. Bill Management has no equivalent. |
| Paging and rows per page | 10 to 1000 rows, default 50. | Always. No gate. |

**Bill Management**

| **Button** | **What it does** | **Appears when** |
|---|---|---|
| New | Opens the bill detail form in a modal. | Management role. |
| Mass Submit for Approval | Submits the selection. | Management role, Status filter not "All", and — the condition Invoice does not have — the account must already have a finance-system Id. This is why bills for unsynced accounts cannot be submitted at all. |
| Mass Approve | Approves the selection. | TL or Accountant branch first, then Bookkeeper or Admin. The role branches are ordered differently from Invoice Management, so the two screens can behave differently for the same person. |
| Mass Reject | Rejects the selection. | Same as Mass Approve. |
| Mass Approve & Issue | Approves and issues. | Bookkeeper only, at Pending Finance Approval. Additionally: if any one selected bill has Block Subsidiary ticked, the whole request aborts and names the blocked bills — nothing is processed. |
| Export To Excel | CSV download. | Same as Invoice. 10,000 row cap. |
| Send Request for Invoice | Queues the bills and opens the send-to-contacts page. | Always visible — no gate at all in the code. Invoice Management gates its equivalent button by profile; Bill Management does not. |
| Download Attachments | Zips the attachments of the selected bills. | Always visible — no gate. No equivalent on Invoice Management. It warns if nothing is selected, but there is no cap on how many records you can select. |
| Block Subsidiary | Opens the subsidiary blocking page. | There are results, and the user is an Admin. |

# 12a. The Invoice detail screen — the buttons and when they appear

Clicking a row on Invoice Management opens FN_InvoiceDetails in a modal. The page is also reachable directly by URL, and that is worth knowing: it accepts only action=view and action=new. There is no edit URL — Edit is an in-page toggle behind the Edit button, so anything reachable in edit mode was reached through that button.

The role model is the same as the list screens. Both use the same handler and the same first-match-wins chain from §10, so a user who sees nothing on Invoice Management sees nothing here either. The difference is scale: the list screen has eight buttons, this page has sixteen, and several of them exist nowhere else in the system.

One rule hides everything. The entire button bar sits inside a single condition — if the invoice is cancelled, or it has been staged to Workday but has not yet come back with a Workday invoice Id, nobody sees any button at all, Admin included. When someone reports that every button has vanished from one specific invoice, this is almost always the reason, and it is not a permissions problem.

| **Button** | **What it does** | **Who sees it, and when** |
|---|---|---|
| Rebuild | Re-pulls the BI data for the activity period and walks you back through the invoice wizard. | Any recognised role. Status must be Pending, Rejected by Supervisor, Rejected by finance, or Submitted and Pending supervisor approval. |
| Refresh | Re-runs the BI update batch for this invoice. | Any recognised role — but only if Run Daily Batch is ticked on the invoice. No status condition. |
| Edit | Switches the page into edit mode. | Admin, Bookkeeper, Accountant: any status except Approved by finance — including Submitted and Pending finance approval. TL and AM: only the four pre-approval statuses. |
| Submit for Approval | Enters the approval process. | Any recognised role. The account must have a finance-system Id, and status must be Pending, Rejected by Supervisor or Rejected by finance. Hidden entirely for AppCloud invoices carrying an unapproved dispute. On click it also demands amount above zero, rate and completions agreeing within 10, and an attachment where the discrepancy reason is Advertiser’s Numbers and the amount is over 50,000. |
| Approve | Approves at the current stage. | Bookkeeper and Admin at either submitted status. TL and Accountant only at Submitted and Pending supervisor approval. AM never. Re-checked on click — only a finance role may set finance approval. |
| Reject | Opens a reason modal, then rejects. | Exactly the same audience as Approve. Reason for Rejection is mandatory. |
| Approve & Issue | Approves and issues to Workday. | Bookkeeper only — not Admin. Status Submitted and Pending finance approval, Not Russia ticked, and the mobile-admin condition satisfied. |
| Recall | Pulls the record back out of the approval process. | AM and Admin only at Submitted and Pending supervisor approval. TL at either submitted status. |
| Reopen | Sets status back to Pending, clears the invoice date and credit amount, flags Reopen. | Bookkeeper only — not Admin. Status Approved by finance, and a Workday invoice Id must exist. |
| Credit & Reissue | Credits in Workday and reissues, keeping the old Workday Id in history. | Bookkeeper only. Reopen ticked, status Submitted and Pending finance approval or Approved by finance, Workday invoice Id present, Not Russia ticked. |
| Partial Credit | Issues a partial credit adjustment against the invoice. | The same five conditions as Credit & Reissue. |
| Cancel Invoice | Full credit, and marks the invoice cancelled. | The same five conditions as Credit & Reissue. Once used, the whole button bar disappears — see the rule above. |
| Sync From WD | Pulls the current state back from Workday. | Any recognised role. Status Approved by finance and a Workday invoice Id present. |
| Split Invoice | Opens the split component. | Anyone who passes the Edit check, plus the same five conditions listed for the list screen in §12: status exactly Pending, no Workday staging or invoice Id, type Invoice, amount above zero, not reopened. |
| Create Dispute | Opens the Create Dispute component. | No role check at all. Account division must be MobileCore, UnityAds, UnityAds Brands, Tapjoy, AppCloud, CTV or Video; status Pending, or Approved by finance and not Paid In Full; amount above zero; type Invoice. |
| Invoice Update | Nothing — it never renders. | Nobody. The visibility flag is hardcoded to false and the real check is commented out. It still exists in the page source, which is misleading if you go looking for it. |

**What to watch on the Invoice detail screen**

  - > **Create Dispute has no role gate.** It is the only invoice action in the system with no role check whatsoever. Anyone who can open a qualifying invoice — including a user with FN Role blank or set to Finance — can raise a dispute from it. The list screen has no equivalent button, so a permissions review done against Invoice Management alone would miss this entirely.

  - > **Five buttons are Bookkeeper-only and exclude Admin.** Approve & Issue, Reopen, Credit & Reissue, Partial Credit and Cancel Invoice all test specifically for Bookkeeper. Admin counts as a finance role but is not a Bookkeeper, so an Admin does not see any of them. This surprises people who assume Admin is a superset of everything.

  - > **Recall gives Admin less than it gives a TL.** Admin is caught by the first branch of the check, which only covers Submitted and Pending supervisor approval, so the branch that would have given Admin the wider TL range is unreachable. A TL can recall at both submitted statuses; an Admin cannot. This reads as a coding slip rather than a decision.

  - > **The same button name means different things on the two screens.** Submit for Approval is stricter here — it also requires the finance-system Id and blocks AppCloud invoices with an unapproved dispute. Approve & Issue is stricter here too, adding Not Russia and the mobile-admin condition. The consequence runs the other way: the mass path on Invoice Management can issue invoices this page would refuse to show a button for.

  - > **Prepayment invoices have no gating.** On a Prepayment invoice the Edit and Save buttons carry no visibility condition at all. Any user who can open the record can edit and save it, whatever their FN Role and whatever the approval status.

# 12b. The Bill detail screen — the buttons and when they appear

FN_BillDetails works the same way — modal from Bill Management, action=view or action=new only, Edit as an in-page toggle — and shares the same role chain through the same handler. Most buttons mirror the invoice page, but the conditions are not identical, and the differences are the part worth reading.

The equivalent hide-everything rule here is the freeze state: a bill that has a Workday staging Id but no final Workday bill Id shows no buttons to anyone. Same symptom, same first question to ask.

| **Button** | **What it does** | **Who sees it, and when** |
|---|---|---|
| Refresh | Re-pulls amounts and lines from BI. | Any recognised role, and only if Run Daily Batch is ticked. No status condition. |
| Edit | Switches the page into edit mode. | Never on CTV bills, at any status, for anyone. Never once the bill is Approved by finance. Otherwise — finance roles: any status. TL: the four pre-approval statuses. AM: the same four minus Submitted and Pending supervisor approval. |
| Submit for Approval | Enters the approval process. | Any recognised role, status Pending, Rejected by Supervisor or Rejected by finance, and the account must carry a finance-system Id. Hidden for AppCloud bills with an unapproved dispute attached. |
| Approve | Approves at the current stage. | TL and Accountant only at Submitted and Pending supervisor approval. Admin and Bookkeeper at either submitted status. AM never. Re-checked on click — only a finance role may set finance approval. |
| Reject | Opens a reason modal, then rejects. | The same audience as Approve. Reason for Rejection is mandatory. |
| Approve & Issue | Approves and issues. | Bookkeeper only. Status Submitted and Pending finance approval, and Block Subsidiary explicitly unticked — if the field is null rather than false, the button does not appear at all. |
| Recall | Pulls the record back out of the approval process. | AM only at Submitted and Pending supervisor approval. TL and Admin at either submitted status. Bookkeeper and Accountant never get Recall — the opposite asymmetry to Approve. |
| Reopen | Back to Pending, clears the bill date, flags Reopen. | Bookkeeper only. Status Approved by finance and a Workday bill Id present. |
| Partial Credit | Partial credit adjustment; marks the bill cancelled. | Bookkeeper only. Status Submitted and Pending finance approval or Approved by finance, Reopen ticked, Workday bill Id present, and Block Subsidiary not ticked. |
| Cancel Bill | Full credit. | The same conditions as Partial Credit. |
| Sync From WD | Pulls the current state back from Workday. | Any recognised role, status Approved by finance, Workday bill Id present. |
| Create Dispute | Opens the Create Dispute component. Runs entirely in the browser — no Apex behind it. | No role check at all. Division must be one of the seven ad divisions; status Pending, or Approved by finance and not Paid In Full; amount above zero; Bill Type is Bill. |
| Add row / remove row (bill lines) | Adds a line, or marks one for deletion. The deletion only happens on Save. | Edit mode, and only on Detailed bills. If Approval Status is blank, everyone. Finance roles: any status except Approved by finance. TL: Pending, Submitted and Pending supervisor approval, Rejected by Supervisor. AM: Pending, Rejected by finance, Rejected by Supervisor. A row can only be removed if it has no statement amount. |
| Amount fields within a row | Editable or read-only. | On Tapjoy, UnityAds, MobileCore and AppCloud bills of type Bill, amounts can only be edited by Admin, Bookkeeper and Accountant. Everywhere else they are editable by anyone who reached edit mode. |
| Upload Attachments | Opens the attachment manager. | In view mode: only at Submitted and Pending supervisor approval, with no role check. In edit mode: on any saved bill, with no role or status check. |

**What to watch on the Bill detail screen**

  - > **Block Subsidiary is enforced here but apparently not on the mass path — verify before relying on either.** This page checks Block Subsidiary on Approve & Issue, Partial Credit and Cancel Bill. On the Bill Management side the field is read into the query but never tested, and the batch filters only on the Workday Id fields. That contradicts what §13 currently says about the mass run aborting on a blocked bill. The Apex alone says it does not — but a trigger, flow or validation rule could still be enforcing it. Confirm in the org before either statement is trusted.

  - > **Submit for Approval is gated on one field and enforced on another.** The button appears based on the account finance-system Id held on the bill; the click-time check reads a different Id field. If the two ever disagree, the user gets an enabled button that hard-errors on click. On the list screen the same split fails silently instead — the record is dropped from the batch with no message. Worth confirming whether the two fields carry the same value.

  - > **Reject is broken on Prepayment bills.** In the prepayment layout the Reject button calls the reject action directly, skipping the reason modal. Because Reason for Rejection is mandatory, it always fails with a validation message unless the field happens to be populated already.

  - > **The create wizard is not gated by URL.** The New button on Bill Management checks that the user is a management role or an Accountant. Opening the detail page directly with action=new checks nothing, so anyone who can load the page gets the full bill creation wizard.

  - > **Attachment links are ungated and unescaped.** Every attachment on the bill is listed as a download link with no role or status condition, and the file name is written into the page without escaping.

**True of both detail pages**

  - > **Neither controller runs with sharing.** Both pages load the record straight from the Id in the URL with no sharing enforcement, so a user who can open the page can open any invoice or bill by changing the Id — including records the list screen would never show them. This is a wider gap than the account-manager narrowing described in §11, which only applies to the list.

  - > **There are no CRUD or field-level permission checks anywhere.** The same finding as the list screens in §12. Access rests entirely on FN Role plus whatever the page chooses to render.

  - > **Only Approve re-checks the role once you click.** Every other action — Reopen, Recall, Reject, Credit, Cancel, Approve & Issue, Save, add and remove line — trusts the fact that the button was rendered. The buttons are a user-interface convention, not a security control. If that distinction matters for SOX, it belongs in the open-items list rather than here.

  - > **Save has no gate of its own on either page.** In edit mode and in prepayment edit mode the Save button carries no visibility condition, and the save method performs its inserts, updates and deletes without re-checking the role. It is protected only by the fact that Edit was gated.

# 13. Mass processes, and the fields that change what you see

**The mass processes**

| **Process** | **What to know before running it** |
|---|---|
| Mass Submit for Approval | Offers two scopes: the records you ticked, or everything matching the current filter. The second is easy to trigger by accident on a wide filter — read the count in the confirmation dialog. |
| Mass Approve / Mass Reject | Same gate as each other. Only acts on records at a status the role is allowed to action; anything else in the selection is skipped rather than reported. |
| Mass Approve & Issue | Bookkeeper only. Always runs asynchronously as a batch, so the screen returns before the work finishes. On bills it refuses the entire request if any selected bill has a blocked subsidiary. |
| Export To Excel | Client-side CSV, capped at 10,000 rows. A wider filter silently truncates. |
| Send Confirmation Mail / Send Request for Invoice | Writes the selection to a helper record keyed on the running user, then opens a separate page. Two people doing this at once are fine; the same person doing it twice quickly is not. |
| Download Attachments (bills only) | Fetches every attachment for the selection and zips them in memory. There is no limit on the query or on the selection size, so a large selection can fail on heap. Select conservatively. |
| Mass Credit | Not on these screens — it lives on the Finance home page, behind the Mass Credit custom permission, and runs as a CSV import. This is the standard route for credit notes. |

**The fields that decide what a user sees and can do**

| **Field** | **On** | **What it controls** |
|---|---|---|
| FN_Role__c | User | Everything. The single gate for both screens — §10. |
| Delegate_User__c | User | Lets another user see this user's records on both screens. |
| Account Manager | Account and the record itself | Whether an AM sees the record at all, and who the approver resolves to. |
| Secondary Advertiser | Invoice | A second route by which an AM can see an invoice. |
| Department | Account | Which screen the record appears on — Advertiser goes to Invoice Management, Publisher and Affiliate to Bill Management. |
| Approval Status | Invoice and Bill | Which approve, reject and issue buttons are available. |
| The finance-system account Id | Account | On bills, whether Mass Submit for Approval works at all. |
| Block Subsidiary | Bill | Aborts a whole Mass Approve & Issue run if set on any selected bill. |
| Correction Period | Bill | The primary filter on Bill Management. Bills outside the selected month and year are simply not in the list. |
| Invoice view type (Detailed / Summary) | Invoice and Account | Whether the invoice reaches Workday at all — §6. |
| Invoiced with / One invoice per | Account | Who gets billed and whether invoices are combined — §4. |

**Gaps in the screen permissions, as they stand**

  - > **Neither screen checks object or field permissions.** There is no CRUD or field-level check anywhere in either controller. Access rests entirely on FN Role plus record sharing.

  - > **Two Bill Management buttons have no gate at all.** Send Request for Invoice and Download Attachments are hardcoded visible for everyone who can open the screen.

  - > **The two screens order their role checks differently.** Approve on Invoice tests Bookkeeper and Admin first; on Bill it tests TL and Accountant first. The same person can therefore get different results on the two screens.

  - > **Send Confirmation Mail is gated by profile name text.** It matches three literal profile-name strings rather than a permission, so renaming a profile silently removes the button.

  - > **The FN Role value "Finance" does nothing.** It is a valid picklist value that the code never tests for. Anyone set to it has no access.

# 14. Who to ask

| **Topic** | **Person** |
|---|---|
| Anything Salesforce-side on invoices and bills | Yakov Asael — the inheriting owner, and already second responder on most of the incidents here. |
| Apex and the management screens | Danill Rekov. Wrote the decimal fix and supplied the targeted refresh scripts. |
| The BI loads and the invoice and line tables | Varun Bhatia. |
| BI query logic and filters | Leehee Bar — found the prefix-match defect behind the Snapsource population. |
| The Workday integration and the migration | Karan, on the integration side. |
| Revenue Accounting — approvals, credits, balances | Maria Zakomorni, Shirel Kaver and Eden Taragan. |
| Bill creation and publisher payouts | Noam Ganzi and Meir Alali. |
| The approver matrix as the business maintains it | Tal Rahamim. |

**Next Step**

**Build the approver-matrix staleness report.** Item 1 in §14 causes more incidents in this document than anything else, it hits invoices, bills and disputes alike, and it is a scheduled report comparing matrix approvers against active users. It pays for itself in the first month.
