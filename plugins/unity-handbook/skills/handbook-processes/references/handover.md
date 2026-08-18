# Handover

> Source: BSA Process Handbook, tab "Handover". Verbatim.

**Handover**

**Process:** Account Handover — users call it an "HO" · **Objects:** Hand_Over__c, Handover_with_Contacts__c · **Date:** 9 August 2026 · **Business owner:** Bar Damti, with Tal Rahamim and Adi Norman Moskovich · **Technical owner:** Dror Diamant → Neta Ronen

**Scope:** this guide covers the Grow Ads record type — the live account-ownership handover. Hand_Over__c also carries 20 legacy record types from the original build (iC, dC, mC, Video, Search, Media, Extensions, Syndication, AppCloud, SuperSonic). Those record types and roughly 50 still-active Workflow Rules on the object continue to fire; they are flagged in §3 and §4 but not documented in detail.

# 1. What this process does.

A Handover moves an account from one owner to another — a new account manager, a new sales manager, or a new ad-ops manager. It exists because ownership drives money: quota, commission, invoice ownership, and whether the client counts as "managed" on the ad platform at all. An unmanaged account is capped at 10 creatives a day, so a delayed handover is a customer-facing problem, not an admin one. The request is raised on the account, approved by up to three managers, and then executed on a fixed calendar rather than on approval. FP&A picks up completed handovers monthly to move quota and commission.

**Lifecycle**

**1.** A user clicks Account Handover on the account. The Grow_Ads_Account_Handover screen flow creates the Hand_Over__c on the Grow Ads record type with Status__c = "On Review" and submits it for approval.

**2.** The Grow HO Process routes it through up to three steps: Current Manager, New Manager, then Senior Manager. Steps whose approver field is blank, or whose approver is the same person as an earlier step, are skipped.

**3.** The Senior Manager step runs only when Quota_Shift_Needed__c = "Yes". That approver reviews the estimated quota and can adjust it or set it to $0.

**4.** On final approval Status__c becomes "Approved" and Approval_Date__c is stamped. The transfer date is then derived from that date and falls on the 5th or the 15th of a month.

**5.** A scheduled flow runs daily, picks up approved handovers whose transfer date is yesterday, rewrites the owner fields on the Account, and sets Status__c = "HO Completed".

**6.** Notification emails go to the new owner and the requestor, and FP&A updates commission tracking once a month from the completed records.

**The one thing a newcomer gets wrong:** approval does not move the account. Nothing changes until the daily job runs on the transfer date. If the transfer date has already passed — because the record was backdated, or created on the same day the job had already run — the job never picks it up, the handover sits at "Approved" forever, and someone has to move it by hand.

# 2. Where records are created, and how they reach their target

| **Entry point** | **How it works and what to know** |
|---|---|
| Account → Account Handover | The one path that matters. This quick action launches Grow_Ads_Account_Handover, which reads the account and its owner, works out the approval route, checks for a duplicate open handover, creates the Hand_Over__c plus one Handover with Contacts row per contact carried across, and submits it for approval. |
| Bulk load by Business Operations | Handovers for more than 20 accounts must go this way. Records are loaded straight onto record type 012Qv000001c9xlIAA with Status = "Approved", which means no approval process runs and no alerts fire — the record exists purely as documentation of a move made another way. |
| BLOCKED — going to SMB with a financial or support problem | The screen flow stops the request when the account is at 90% or more of its credit limit, or has an open case, and the destination is SMB. Users report this as "Unable to HO for 'there is open case' but there is no" — the case may be one they cannot see. |
| BLOCKED — hardcoded account and user | Block_HO_Creation_for_accounts_by_id blocks one specific account ID and one specific new-owner user ID. Both are hardcoded in the rule formula, so the UI gives no clue why (§4). |

**How the handover reaches the account**

  - > Approval alone changes nothing on the Account. The record only carries the intent.

  - > The daily scheduled flow rewrites the Account owner fields chosen by HandOver_Type__c — Account Manager, Sales Manager or Ad-ops Manager — and only for handovers whose transfer date is yesterday.

  - > Transfers from Onboarding to SS TLV and from managed teams to SMB take their own branch inside that flow and move immediately rather than waiting for a cycle.

  - > The user cannot set the transfer date. It is derived from the final approval date, and backdating was deliberately removed.

  - > The user cannot recall a handover back to draft. Recall rejects it, and a rejected handover has to be raised again from scratch (§5).

# 3. The flows — what each does and what triggers it

Eleven active flows. Three carry the process: Grow_Ads_Account_Handover creates and routes the request, Grow HO Process approves it, and HandOver_Update_new_owner_on_transfer_date is the only thing that actually moves the account.

| **Flow** | **Trigger** | **What it does** |
|---|---|---|
| **CREATION** | | |
| Grow_Ads_Account_Handover | Screen — Account Handover quick action on Account | When a user raises a handover from an account, it decides the approval route from the type and the division, stamps Current_Manager__c, New_Manager__c and Senior_Manager__c, blocks the request when the destination is SMB and the account is ≥90% of its credit limit or has an open case, warns when a duplicate handover already exists, creates the Hand_Over__c and a Handover with Contacts row per contact, and submits it for approval. The most incident-prone thing here — it throws "You can't create hand over request for this account" and "No applicable approval process was found" in production. |
| **APPROVAL & QUOTA** | | |
| HandOver_Calculate_Estimated_Quata_Amount | Hand Over, after save on update — Status__c becomes "Approved" or "HO Completed", or Transfer_Date__c changes, with Quota_Shift_Needed__c = "Yes" | Recalculates the quota to move: it averages the first 7 days of the current quarter and the last 30 days of the previous quarter, scales that daily rate across the days left in the quarter from the transfer month, and writes Suggested_Amount__c and G_A_Completed__c. |
| Handover_Reject_Automatically_after_open_for_30_days | Hand Over, scheduled daily at 03:30 UTC — Reject_Automatically__c = TRUE | Closes out handovers that have sat unapproved: sets Status__c = "Rejected", publishes an approval platform event to kill the running approval, and writes an ErrorObject__c record on failure. Users report handovers rejecting immediately on submit — verify whether Reject_Automatically__c is being set too early. |
| **TRANSFER EXECUTION** | | |
| HandOver_Update_new_owner_on_transfer_date | Scheduled daily at 11:30 UTC | Collects approved handovers whose transfer date is yesterday, rewrites the Account owner fields according to HandOver_Type__c, routes Onboarding→SS TLV and managed→SMB moves down their own branches, sets Status__c = "HO Completed" and publishes the email-notification event. A handover whose transfer date has already passed is never collected, which is why approved handovers get stuck. |
| **NOTIFICATIONS** | | |
| Handover_Run_Notification_Flow | Hand Over, after save when Approver_Slack_ID__c changes and is not blank | Sets Run_Notification_Flow__c = TRUE. This flag is the only thing that starts a Slack notification — an approver with no Slack ID is never pinged. |
| HandOver_Slack_Notifications | Hand Over, after save when Run_Notification_Flow__c = TRUE and a Slack ID exists | Sends the approver the Centro Slack card with Approve and Reject buttons, then clears the flag. Fails intermittently with UNABLE_TO_LOCK_ROW when the record is being written by something else at the same moment. |
| Hand_Over_Send_Notification_to_Approver | Scheduled daily at 20:00 UTC — Grow Ads record type, Status__c = "On Review", Notification_Counter__c ≥ 2, Current_Approver_Email__c not blank | Emails the current approver the Hand Over Approval Notification alert and stamps Time_For_Notification__c. This is the chaser that goes out every two days while a request sits unapproved. |

**Two things to check before you change anything here.** Hand_Over_Unlock_for_FP_A_Team is inactive in the org, yet the Grow HO Process still sets Run_Unlock_Flow__c on final approval — verify whether anything unlocks approved records for FP&A today. And roughly 50 Workflow Rules on Hand_Over__c are still active from the original build, several of which write the Account owner directly; they fire only on the legacy record types, but they are a second, undocumented automation framework on the same object.

# 4. Validation rules — what blocks users and why

| **Rule** | **What it blocks** | **Error the user sees** | **Why it exists** |
|---|---|---|---|
| **GROW ADS HANDOVER — active validation rules. Change these in Setup → Object Manager → Hand Over.** | | | |
| Block_HO_Creation_for_accounts_by_id | Creating a handover for one specific account, or to one specific new owner | "You can't create hand over request for this account" | A deliberate block on a single account and a single user. Both are hardcoded 18-character IDs in the formula, so neither the user nor the admin can tell from the UI which one fired. This is the most common handover error in production. |

*Four of the 18 validation rules on Hand_Over__c are inactive, including Cant_Modify_Account_Finance_fields, which would have blocked a handover when the billing country, legal entity or payment terms had drifted from the account after it synced to NetSuite. If a stakeholder tells you finance data is validated at handover, it is not.*

# 5. Approval processes — what exists and what triggers each

| **Approval process** | **Object / record type** | **What triggers entry** | **Who approves** | **Approve vs reject** |
|---|---|---|---|---|
| Grow HO Process | Hand_Over__c — Grow Ads record type only | RecordType = "Grow Ads" AND Status__c = "On Review". The screen flow sets both and submits the record. | Three sequential steps, each reading a user field on the record. Step 1 Current_Manager__c, skipped when blank. Step 2 New_Manager__c, skipped when the submitter is already the new owner's manager or when the new manager is the same person as the current manager. Step 3 Senior_Manager__c, which runs only when Quota_Shift_Needed__c = "Yes" and the senior manager is not already one of the first two approvers. | Approve: Status__c set to "Approved", Approval_Date__c stamped, the current-approver fields cleared, the record unlocked for FP&A, and the new-owner alert sent. Reject: Status__c set to "Rejected" and the rejection alert sent to the creator. |

**Recall does not mean recall.** The process allows recall, but the recall action sets Status__c = "Rejected" — the request cannot be pulled back for editing, it can only be killed and raised again. Record editability is Admin or current approver, so an ordinary user cannot correct a request mid-flight. If the current manager has left the company and the request is stuck, edit Current_Manager__c to yourself and click Submit for Approval again.

# 6. The approver matrix

Approvers are stamped onto the record when the screen flow creates it, not resolved live at approval time. That one fact explains most approval bugs: if the org chart changes, or an approver leaves, existing handovers keep the old approver and have to be repaired record by record. Current_Manager__c and New_Manager__c come from the two owners' manager fields on the User record. Senior_Manager__c is looked up from the Team_Report_Region_Mapping__c custom setting on Team_Name__c, which returns Ads_HO_region__c, Ads_HO_senior_Manager__c and Ads_HO_senior_Manager_Name__c — so changing a senior approver is a configuration change, not a code change. When no row matches the team, the flow falls back to a hardcoded user ID, which is why unexpected people appear as approvers. The org is authoritative; the HO Senior Manager Mapping sheet in Drive is the upload source for it, and the two have drifted apart.

| **Step** | **Approver field** | **Runs when** |
|---|---|---|
| 1 — Current Manager | Current_Manager__c | Always, unless the field is blank. Skipped for same-team moves, where the screen flow routes down its Team-Lead-only branch. |
| 2 — New Manager | New_Manager__c | Only when the submitter is not already the new owner's manager, and the new manager is a different person from the current manager. |
| 3 — Senior Manager | Senior_Manager__c, from Team_Report_Region_Mapping__c | Only when Quota_Shift_Needed__c = "Yes" and the senior manager is not already approver 1 or 2. This approver reviews the quota and can set it to $0. |

**Exceptions that override the normal path**

  - > Same-team moves take the Team-Lead-only route in the screen flow and transfer immediately, outside the twice-monthly cycle.

  - > Ad-ops handovers on MobileCore, UnityAds and Tapjoy can be approved automatically and transferred straight away, because those managers do not carry commission on the account.

  - > Transfers to SS TLV are pre-approved by the SMB team and need Team Lead approval only. Note the skip works in one direction only — moving to SS skips the SMB approval, moving to SMB does not.

  - > Handovers loaded in bulk by Business Operations enter at Status = "Approved" and never touch this process at all.

  - > When the team has no row in Team_Report_Region_Mapping__c, the senior manager falls back to a hardcoded user rather than failing — the request goes through, to the wrong person.

# 7. Other mappings in the process

| **Source** | **Target** | **When and why it matters** |
|---|---|---|
| Team_Report_Region_Mapping__c (custom setting) | Senior_Manager__c and the HO region on the handover | The single point of failure for step 3. A missing team row sends the approval to the hardcoded fallback user instead of the right senior manager. |
| HandOver_Type__c | Which Account fields the daily job rewrites — Account Manager, Sales Manager or Ad-ops Manager | Pick the wrong type and the handover completes successfully while changing the wrong field. Nothing downstream will flag it. |
| Hand_Over__c → Handover_with_Contacts__c | One row per contact carried across at creation | The new owner's view of who to talk to. Populated only by the Grow Ads screen flow, so bulk-loaded handovers have none. |
| Suggested_Amount__c and Quota_Shift_Needed__c | The quota FP&A moves between the two owners | Quota Shift defaults to Yes for Account Manager and Ad-ops Manager moves. If the senior manager zeroes it, no quota moves — and that decision is invisible anywhere except the approval history. |

# 8. Notifications

| **Notification** | **Trigger** | **Recipients** | **Channel** |
|---|---|---|---|
| Approval request | Handover submitted into any step of Grow HO Process | Current approver | Email, plus the standard Salesforce approval request |
| Slack approval card | Approver_Slack_ID__c populated → Run_Notification_Flow__c = TRUE | Current approver | Slack, via the Centro app — Approve and Reject buttons in the message |
| Approver chaser | Scheduled daily; Status "On Review" and Notification_Counter__c ≥ 2 | Current approver | Email — Hand Over Approval Notification, repeating every two days |
| Handed over and assigned to you | Final approval (FinalAlertOwner) | New owner, plus a list of named users baked into the alert | Email — carries type, new and current owner, requestor, quota shift and transfer date |
| Handover was rejected | Final rejection | Creator, plus named users baked into the alert | Email |
| Transfer completed | Daily transfer job sets Status = "HO Completed" | New owner and previous owner | Email, raised through a platform event |

*Several email alerts still name individual users directly rather than a role or a queue, and some of those users have left. If someone says they stopped getting handover emails, or that they are getting handovers that are not theirs, check the alert recipients before checking the flow.*

# 9. FAQ

**Check these five first:** (1) What is Status__c — "On Review", "Approved" or "HO Completed"? (2) Is Transfer_Date__c in the past? (3) Are Current_Manager__c, New_Manager__c and Senior_Manager__c populated, and are those users still active? (4) Is Quota_Shift_Needed__c "Yes", and did step 3 run? (5) Is the destination SMB, and does the account have an open case or ≥90% credit used?

| **Symptom, in the user's words** | **Cause and fix** |
|---|---|
| "Handovers Bulk" — the single most common ticket, 19 cases with this exact subject | Not a fault. Any move of more than 20 accounts is supposed to go to Business Operations as a bulk load rather than through the button. Use the HandOver Template (§11); records land at Status "Approved" and skip the approval process entirely. |
| "We submitted and approved a handover for an account… but both 'approved' handovers haven't advanced to the 'HO complete' stage." | The daily transfer job only collects handovers whose transfer date is today. If the date has passed — backdated, or created after the job already ran that morning — it is never collected. Set Transfer_Date__c to today and it will complete overnight, or move the account manually. |
| "Cannot normally submit HO request for approval" / "Unable to HO for 'there is open case' but there is no" | The screen flow blocks moves to SMB when the account is at ≥90% of its credit limit or has an open case (§4). The case is often one the requester cannot see. Check the account's open cases and credit percentage, close or reassign the blocker, then resubmit. |
| "You can't create hand over request for this account" | Block_HO_Creation_for_accounts_by_id (§4). One account ID and one new-owner user ID are hardcoded in the rule. Open the rule in Setup and compare the IDs — nothing in the UI tells the user which one they hit. |
| "Now it says submit for approval, but that no approval process was found." | The record is not on the Grow Ads record type, or Status__c is not "On Review" (§5). Bulk-loaded and legacy-record-type handovers will never match. This fault is live and recurring on Grow_Ads_Account_Handover. |
| "Do you know why this went to Tal Rahamim's approval? She isn't listed as one of the senior managers in my matrix." | The team has no row in Team_Report_Region_Mapping__c, so the flow used its hardcoded fallback approver (§6). Add the team row to the custom setting; existing handovers keep the wrong approver and need reassigning by hand. |
| "There are several requests stuck because the current account manager has already left and I can't approve them myself." | Edit the handover, set Current_Manager__c to yourself, then click Submit for Approval again. It will route to you. This is the standard repair and it is not documented anywhere else. |
| "I got this error on SFDC when trying to do the Handover to SelfServeSS team." | When moving an account to self-serve you must choose SS TLV as the new owner, not an individual user. Picking a person fails validation on the screen. |
| "The handover process was complete for this account but it still is not showing on Unity Dashboard — the client is flagged as an unmanaged account." | The handover finished; the downstream sync to the ad platform did not. This is not a Hand_Over__c problem. Run the account sync procedure and, if it persists, raise a GTM case — the creative cap stays at 10 a day until it clears. |
| "I accidentally created this HO. Can you help delete or reject it?" | Users cannot recall or delete their own handovers by design (§5). Recall sets the status to Rejected. Business Operations or the SFDC team rejects it, then the user raises a new one. |
| "I have two HOs in Salesforce that were rejected the moment I clicked submit. What should I do?" | Recurring and not yet root-caused. Handover_Reject_Automatically_after_open_for_30_days rejects anything with Reject_Automatically__c = TRUE, and the 30-day condition appears to be evaluating too early on some records. Check that field on the rejected record before re-raising, and treat this as an open bug. |
| "I've submitted some HO requests and approved them myself, but all of those are still on current owners." | A time-zone effect. Approvals made in the early morning by APAC users are stored against the previous day in the org's time zone, so the transfer date lands behind the job. Set Approval_Date__c to today and the record will process overnight. |
| "Team Commission - April Numbers are missing for a lot of accounts that we handovered." | Quota only moves when Quota_Shift_Needed__c = "Yes" and the senior manager step actually ran (§6). If the senior manager zeroed Suggested_Amount__c, or step 3 was skipped because the senior manager was also approver 1 or 2, no quota moved. FP&A reconciles monthly, so this surfaces weeks later. |
| "I am not in cc of my Handover emails." | The handover email alerts have individual users hardcoded as recipients rather than roles, and some of those users have left (§8). Fix the recipient list on the alert in Setup, not the flow. |

*Escalation: handover policy, approver-matrix content and bulk loads go to Bar Damti or Adi Norman Moskovich. Salesforce configuration, stuck records and datafixes go to Yakov Asael. Users raise everything through the GTM support case form; day to day the process lives in #ask-grow-salesops, and the build history is in the private #am-changes-project channel.*

# 10. Dashboards and reports

**There is no handover dashboard in the org.** A query on every dashboard title returned none. There is also no scheduled, emailed handover report — nothing in this process alerts anybody automatically, which is why stuck approvals are found by users rather than by the team.

| **Report** | **Folder** | **What it is for** |
|---|---|---|
| **DAILY / OPERATIONAL MONITORING** | | |
| [Hand Over Approval Monitor](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000ECuJLMA1/view) | Public Reports | The closest thing to a control panel — who is holding what, and for how long. Start here when someone says a handover is stuck. Three older copies of this report exist under the same name; this is the one still being run. |
| [Open Handovers more than 7 days](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000HVeAfMAL/view) | Public Reports | The ageing list. Anything here is heading for the 30-day automatic rejection. |
| **QUOTA, COMMISSION AND FINANCIAL CLOSE** | | |
| [FP&A pending Grow Ads Handovers](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000EGbWbMAL/view) | Public Reports | What FP&A works from each month. The matching list view on the object carries the same name. |
| [Account Handover - FP&A Completed](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv000006xmwPMAQ/view) | Public Reports | Handovers FP&A has already processed for commission. |

*"Public Reports" is doing the work of a proper folder here — the handover pack is scattered across it, "HO requests", "usefull reports" and the compensation team's own folder, with several same-named copies. Consolidating them into one owned folder would be a cheap first improvement for whoever takes this over.*

# 11. Related documents

| **Document** | **Type** | **Open this when…** | **Status** |
|---|---|---|---|
| **REQUIREMENTS & DESIGN** | | | |
| [2026 Account Handover Guide](https://docs.google.com/document/d/1BTztSLKJvB01Y2FBXkmw0dnV8U9k7z1DycNLb2I0Z3E/edit) | Doc | You need the business rules as the business states them — approval chain, quota shift, transfer cycle and the user-facing FAQ. The published entry point for end users. | Current — the live business guide |
| **MATRICES & MAPPINGS** | | | |
| [HO Senior Manager Mapping 290126](https://docs.google.com/spreadsheets/d/1a5MsOq_7_t4x5rRbRZZ3YLUaap2qJifvlM9hVo8Enfg/edit) | Sheet | You are investigating an older handover and need the team-to-senior-manager state as it was earlier in the year. | Superseded |
| **Templates** | | | |
| [New Handover Template](https://docs.google.com/spreadsheets/d/1CAQn2iIjvElt-KmbGPwiOgDQVVaQ1MG_Yoxo4hy4C24/edit?gid=0#gid=0) | Sheet | You need the exact API names of the newest fields and of the Handover with Contacts object. | Current — deployment component list |
| **BACKLOG** | | | |
| [Handover - Wishlist](https://docs.google.com/spreadsheets/d/1ZJvEE2VD31ICdwq-1nsW1_a7xxMtgm99-SKYOVpdfA4/edit) | Sheet | A stakeholder asks whether a change was ever requested or delivered — the de-facto change log for the process. | Current — live backlog |

*There is no PRD and no TDD for the current handover build, no go-live plan, and no standalone QA document. The only formal design document in Drive describes a system that no longer runs. That absence is the single biggest documentation risk in this handover.*
