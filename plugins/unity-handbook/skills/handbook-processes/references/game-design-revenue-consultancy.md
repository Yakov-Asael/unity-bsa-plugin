# Game Design Revenue Consultancy

> Source: BSA Process Handbook, tab "Game Design Revenue Consultancy". Verbatim.

**Game Design & Revenue Consultancy**

**Process:** Game Design & Revenue Consultancy — the team says "GDRC", users say "ticket" · **Object:** Case, record type Game_Monetization_Consultancy only · **Date:** 10 August 2026 · **Business owner:** Franco Spina, with Nathan TenBoer · **Technical owner:** Dror Diamant → Hagar Itzhak

*§1–2 how the process works · §3–9 how it is built · §10 troubleshooting · §11–12 where to look next.*

# 1. What this process does

GDRC is a consulting team that does monetization and game-design work for LevelPlay publisher clients — game audits, monetization teardowns, workshops and bespoke reviews. A Client Partner raises a ticket against a specific client game; the team qualifies it, scopes it, delivers a report or a deck, and the Client Partner takes the recommendations back to the studio. The Case record is the intake queue, the work tracker and the evidence of commercial impact. Volume is deliberately low — 80 cases in total — because a single ticket can be six weeks of work. This is a small, high-touch process, and its value comes from the discipline of the stage gates rather than from throughput.

**Lifecycle**

**1.** The Client Partner creates the case from the global action. Nothing else can create one, and a validation rule enforces that.

**2.** GDRC qualifies it internally. The case cannot leave Internal Qualification until Category, Attribution Type and the initial success objective are filled in.

**3.** Discovery and scoping — "Research" and "Design" in the picklist. An agreed KPI is mandatory before the case can leave Design.

**4.** The studio approves the proposal ("Pending Approval"), a consultant is assigned, and the case moves to "To do" and then "In progress".

**5.** Delivery, then follow-up and an impact check ("Monitoring"). Closing requires a KPI outcome summary and Team Lead sign-off.

# 2. Where records are created, and how they reach their target

| **Entry point** | **How it works and what to know** |
|---|---|
| Global action → "Game Design & Revenue Consultancy" | The only supported path, and the only one the team will tell a user about. It is a Lightning component quick action, Game_Design_Revenue_Consultancy_component, not a screen flow — so it cannot be edited in Flow Builder. Behind it sits the screen flow Case - Create new case for Game Monetization Consultancy, which looks up the account, the internal app and the destination queue and creates the case. |
| From a parent case | The same creation flow accepts a parent record and links the new case to it. This is how a follow-on engagement is tied to the original, using the standard Parent Case relationship rather than a custom field. |
| Bulk load by the Salesforce team | Historic engagements were loaded from a spreadsheet rather than created through the component, straight onto the record type with Status = Closed. Those rows carry the old Request Type and Client Type taxonomy and no Category or Attribution Type, so they will look empty in any new report. |
| BLOCKED — the standard New button | GDRC_can_be_created_only_from_screen stops it and tells the user exactly where to go instead: "Please go to the global action (+) in the top right of the page, and click on Game Design & Revenue Consultancy." This is the only validation rule on this record type that is definitely still active. |

**How a ticket reaches a consultant**

  - > New cases land in the Game Monetization Consultancy queue. They are not auto-assigned and there is no assignment rule — the case sits with the queue until a human takes it.

  - > Assignment is manual and leadership-only. Franco Spina and Nathan TenBoer set the owner by hand once the case has been qualified.

  - > A game that does not yet exist in Salesforce can still be ticketed. The creation screen carries an "Application doesn't exist" checkbox that switches the application field to free text — added because unreleased titles were blocking requests entirely.

  - > A publisher with no Salesforce account has a generic placeholder account to use. Ask the Salesforce team for it rather than creating a new account.

  - > Progress is driven entirely by Status. There is no approval process record, no entitlement and no milestone behind any of it (§5).

# 3. The flows — what each does and what triggers it

Five active flows, and ten inactive ones left in place. Every active flow filters on RecordType.DeveloperName = "Game_Monetization_Consultancy", so none of them touches any other kind of Case. The Notifications flow is the one that matters — it carries the entire alerting model, and §9 takes it apart.

| **Flow** | **Trigger** | **What it does** |
|---|---|---|
| **CREATION** | | |
| Case_Create_new_case_for_Supply_Consultation | Screen — behind the global action, and from a parent case | When a Client Partner opens the global action, it collects the account, the game, the request detail and any attachments, resolves the record type and the destination queue, and creates the case. Note the API name: it is inherited from an older "Supply Consultation" build and has nothing to do with supply. The label is the accurate one. |
| **VALIDATION AND STATE** | | |
| Case_Game_Monetization_Consultancy_Before_Record_Save_Actions | Case, before save | Sets field values on the record before it is written — including the status-change timestamp the whole alerting model depends on. Not present in the metadata repo snapshot, so read it in Flow Builder before changing anything near it. |
| Case_Game_Monetization_Consultancy_Triggers (label: "Validations") | Case, after save whenever Status changes | Enforces six stage gates with custom error messages — every one of them listed in §4. The label and the API name disagree: it is a validation flow, not a trigger router. |
| **NOTIFICATIONS** | | |
| Case_Game_Monetization_Consultancy_Notifications | Case, after save on create, and whenever Status changes | The whole alerting engine. It reads the GameMonetizationConsultancyAlerts__c custom setting for the new status, works out who should be told, resolves their Slack IDs, and sends either an immediate message or a scheduled ageing reminder at 7, 10, 14 or 30 days in the same status. Writes an ErrorObject__c record when it fails. Version 17, and the most edited thing here. §9 explains how each part of each message is built. |
| **SUPPORTING** | | |
| Case_Game_Monetization_Consultancy_Similar_Cases | Screen — launched from the case | Shows other cases on the same account or game so a consultant can see what was done before. Read-only; it changes nothing. |

# 4. Validations — everything that can block a user

*There are eleven of them, in two places, and they behave differently. Five are classic validation rules in Setup, of which only one reads as active in the metadata snapshot. The other six are custom errors raised by the Validations flow, and those are the ones firing today. Every message below is quoted exactly as the user sees it, typos included, because that string is what they will paste into a ticket.*

| **Rule** | **What it blocks** | **Error the user sees** | **Why it exists** |
|---|---|---|---|
| **VALIDATION RULES — Setup → Object Manager → Case → Validation Rules** | | | |
| GDRC_can_be_created_only_from_screen — ACTIVE | Creating a GDRC case anywhere except the global action | "You can't create a case for the Game Design & Revenue Consultancy team from here. Please go to the global action (+) in the top right of the page, and click on Game Design & Revenue Consultancy." | A case created any other way skips the component and arrives with no account, no game and no queue. The rule checks the SF_Case__c flag that only the component sets. |
| **CUSTOM ERRORS RAISED BY the flow Case_Game_Monetization_Consultancy_Triggers — these are the live gates** | | | |
| Can_t_move_from_Internal_Qualification | Leaving Internal Qualification while Attribution Type, Category or the initial success objective (Suspended_Reason__c) is blank | "You can't change the status from Internal Qualification if one of the following field is blank: Attribution Type, Category, Initial Success Objective" | These three decide whether a formal KPI becomes mandatory later, which service line the engagement belongs to, and what it is trying to achieve. The message names the business label; §7 tells you which field actually holds it. |
| Can_t_move_from_Design | Leaving Design while Agreed_KPI_Success_Metric__c is blank | "In order to change the status from Design, please fill to field Agreed KPIs / Success Metric" | No agreed success metric means nothing to measure at the impact check. The spec says this should apply only when Attribution Type is Direct — the flow applies it to every engagement. Worth raising. |
| Can_t_move_to_Rejected | Moving to Rejected while Next_Steps__c is blank | "You can't change the status to Rejected before you add a rejection reason." | A declined request has to tell the Client Partner what to do instead. Note the mismatch: the message says "rejection reason", the field is Next Steps. |
| Can_t_move_to_On_Hold | Moving to On-Hold while Network_Rejection_reason__c is blank | "You can't change the status to On Hold before you add an On Hold reason." | A blocked engagement with no stated reason cannot be chased, and the On-Hold escalation in §8 has nothing to report. |
| Can_t_move_to_Delivered | Moving to Delivered while CP_Attended_Pre_Delivery_Alignment__c is false | "You can't change the status to Delivered before CP attended pre-delivery alignment" | The Client Partner has to see the deliverable before the client does. This is a checkbox, so it blocks until someone ticks it — including on engagements where no alignment call happened. |
| Can_t_move_to_Closed · Can_t_move_to_Closed_Sign_of_missing | Closing while the KPI outcome summary is blank, or while Team Lead sign-off (Legal_Q5__c) is false | "You can't change the status to Done before filling the KPI outcome summary field." · "You can't change the status to Done before TL singed off" | The outcome summary is the only evidence the engagement produced anything. Two separate errors so the user knows which one they hit. Both test Status = "Done" — but §7 maps the closing stage to "Closed", so verify which value is actually live. |

# 5. Approval processes

None found. There is no Salesforce approval process on this record type — no ProcessDefinition, no approval steps, no approval history. What the team calls "approval" has always been a status value change from "Pending Approval" to "To do".

# 6. Who approves and who assigns

This process is not matrix-driven, so there is no lookup table to maintain. Approval and assignment are manual and deliberately concentrated in two people: Franco Spina, who owns the process and the service taxonomy, and Nathan TenBoer, who does day-to-day assignment and is the designated cover when Franco is away.

# 7. Other mappings in the process

The spec and the org use different names for the same stage. This table is the translation, and it is the single most useful thing in this guide — the picklist values on the right are what you will find in reports, list views and the Kanban.

| **Stage name the business uses** | **Status value in Salesforce** | **Note** |
|---|---|---|
| Internal Qualification | Internal Qualification | The GDRC-side gate. Attribution Type, Category and success objective required to leave. |
| Discovery | Research | A discovery call with the studio. |
| Scoping | Design | Agreed KPI required to leave. |
| Awaiting Approval | Pending Approval | This is the studio approving the proposal, not an internal approval. |
| Declined — Archived | Rejected | Requires next steps to be recorded. |
| In Pipeline | To do | Approved and consultant assigned, work not started. |
| Blocked | On-Hold | Requires a reason. Escalates to Leadership after 14 days or on high priority. |
| Delivery | Delivered | Requires confirmation the CP attended the pre-delivery alignment. |
| Impact Check | Monitoring | Where the agreed KPI is actually measured. |
| Closed — Done | Closed | Requires KPI outcome summary and Team Lead sign-off. |

# 8. Notifications

Every alert in this process is configured as data, not as code. GameMonetizationConsultancyAlerts__c holds one row per status, and the Notifications flow reads it on every status change. Each row says who to tell — creator, owner, Account Manager, GDRC Team Leader, GDRC Leadership — whether to send immediately, and how many days to wait before chasing.

| **Notification** | **Trigger** | **Recipients** | **Channel** |
|---|---|---|---|
| Case created | A new GDRC case is saved | The GDRC Slack channel and the case owner | Slack via Centro, plus email — carries account, region, category, attribution type, priority, owner, subject, status, client type and request type |
| Submitted for your approval | Status moves to Pending Approval | Approver and Team Leader | Slack and email |
| Assigned to you | A consultant is set as owner | The consultant | Slack and email |
| Case is blocked | Status moves to On-Hold | Client Partner and Team Leader immediately; GDRC Leadership after 14 days or when priority is high | Slack and email |
| Ready for delivery | Status moves to Ready | Client Partner — "Please schedule a delivery session with the client" | Slack and email |
| Ageing reminder | A case sits in the same status past its configured threshold — 7, 10, 14 or 30 days depending on the status | Per the custom setting row: owner, Account Manager, Team Leader or Leadership | Slack and email — the message names the status and the number of days |

# 9. How the notifications are actually built

Nothing in §8 is a Salesforce email alert and nothing is configured in Slack. Every message is assembled at run time inside Case_Game_Monetization_Consultancy_Notifications from three ingredients: a row in the GameMonetizationConsultancyAlerts__c custom setting, a handful of formulas, and a text template holding raw HTML. This section says which ingredient controls which part of the message, so you can change the right one.

**Two paths through the same flow**

| | **Immediate path** | **Scheduled path** |
|---|---|---|
| Fires when | The case is created, or its status has just changed | The case has sat in the same status for the number of days configured on the row |
| Reads the custom setting as | Get_Alert_Mapping — matched on the new status | Get_Custom_Setting — matched on status plus day count |
| Reads the case from | $Record, the record that just triggered the flow | Var_Case, a fresh query. The message therefore reflects the case as it is now, not as it was when the timer started |
| Day counter | Not used | Days_In_Current_Status = TODAY() − DATEVALUE(New_Status_Date_Time__c). That timestamp is written by the before-save flow, and only on creation or a status change |
| Templates used | EmailBody and SlackBody | EmailBody_Scheduled and SlackBody_Scheduled |

**Where each part of the message comes from**

| **Part of the message** | **Built by** | **What it resolves to** |
|---|---|---|
| **EMAIL** | | |
| Subject | SubjectFormula | Immediate: "Case " + CaseNumber + " " + the Subject__c text on the custom setting row — so the wording is data you can edit. Scheduled: "Case `<number>` - `<status>` Alert (`<n>` Days)" — hardcoded in the formula, so changing it means editing the flow. |
| Recipients | Email_Rec_Formula → Recipients_String | Builds a comma-separated string in a fixed order: Account Manager (PlayDev_Owner__r.Email), creator, owner, then the two custom labels GDRC_Team_Leader and GDRC_Leadership. Each is included only if the matching checkbox on the row is ticked. Recipients_String then strips the trailing comma. If every checkbox is off, the string is empty and no email is sent. |
| Body | EmailBody / EmailBody_Scheduled | Inline HTML written into the flow, not a Salesforce email template: dark header bar reading "New Notification - Game Design & Revenue Consultancy", a white card, and a grey footer "This is an automated message generated by Unity Salesforce. Please do not reply directly to this email." To restyle the email you edit HTML inside a flow resource. |
| The one variable sentence | Alert_Description__c on the row | Immediate: "Case `<number>` " followed by this text. Scheduled: "This case has been in `<status>` status for `<n>` days." then this text. This is the field to edit when the business wants different wording. |
| The case details block | Hardcoded in the template | Account Name, Region (Publisher_Timezone__c), Category, Attribution Type, Priority. Adding a field to the message means editing the template HTML in both the immediate and the scheduled version. |
| The On-Hold line | On_Hold_Reason | Appends "On Hold Reason: `<value>`" only when Status is On-Hold; empty otherwise. |
| **SLACK** | | |
| Destination | SlackID / SendToSlackID | First match wins: the creator's Slackid__c if Send to creator is ticked, otherwise the owner's Slackid__c if Send to owner is ticked, otherwise the channel ID in UserSlackID_Channel_ID__c. Only one destination per message. |
| Body | SlackBody / SlackBody_Scheduled | The same content as the email with the HTML wrapper stripped, sent through the Centro SendMessageFlow Apex action with usePlainText = true. |
| Button | Hardcoded on the action | A single "Open Case" button pointing at the Lightning record URL with the case Id substituted. Immediate path only — the scheduled Slack message has no button. |

**What to change, and where**

  - > To change WHO gets an alert: tick or untick the checkboxes on the custom setting row. No flow change, no deployment.

  - > To add a recipient who is not the creator, owner, AM, TL or Leadership: put the address in Emails__c on the row.

  - > To change the WORDING of the message: edit Alert_Description__c on the row. Anything beyond that one sentence means editing HTML in a text template.

  - > To change an immediate subject: edit Subject__c on the row. To change a scheduled subject: edit SubjectFormula in the flow.

  - > To change the escalation timing: change Scheduled_Num_Of_Days__c on the row.

  - > To change who receives Team Leader or Leadership alerts: edit the custom labels GDRC_Team_Leader and GDRC_Leadership. They hold real email addresses and are pasted straight into the recipient string, so multiple addresses must be comma-separated and correct — a bad value silently breaks the whole send.

# 10. FAQ

**Check these five first:** (1) Is the case actually on this record type, or is it a different kind of Case? (2) What is Status, and is it an old value or a new one (§7)? (3) Is the user in the Game Monetization Consultancy queue and do they hold the GDRC permission set? (4) Was the case created through the global action, or bulk-loaded? (5) Is the flow behind the button they are pressing actually active (§3)?

| **Symptom, in the user's words** | **Cause and fix** |
|---|---|
| "The team are not able to move tickets to different statuses. E.g — from 'to do' > 'in progress'. It appears only myself or Nathan can do it." | The old approval gate. Cant_change_status_before_approval blocked any status change until the case was approved, and exempted only holders of Game_Monetization_Consultancy_Submit_Permission. That rule now reads as inactive, and the stage gates live in flow instead (§4) — if this recurs, it is the flow, not the rule. |
| "I'm unable to move this ticket from suspended back into in progress — states that I have to approve it first?" | Same gate, seen from the other direction. Confirm whether the case has an approval timestamp; if not, either approve it or move it with a user who holds the submit permission. |
| "Tried to move the ticket to Delivered but got the following message, I already added a delivery date." | The delivery-date rule is inactive. What blocks Delivered today is the pre-delivery alignment checkbox (§4) — the message names it explicitly, but users read any error on that transition as being about the date. |
| "In order to change to suspended, suspended reason is required." | On-Hold needs a reason, and the field is Network_Rejection_reason__c — not a field anyone would guess from the name (§7). Fill it and the status will move. |
| "You can't change the status from Internal Qualification if one of the following field is blank…" | Three fields, and one of them is hiding. Attribution Type and Category are obvious; "Initial Success Objective" is stored on Suspended_Reason__c (§7), so a user scanning the layout for a field with that name will not find it. |
| "You can't create a case for the Game Design & Revenue Consultancy team from here." | The user pressed the standard New button on Case. Send them to the plus icon in the top right and the "Game Design & Revenue Consultancy" global action — that is the only path that populates the account, the game and the queue. |
| "Is there any chance we can make 'application name' not bound by one already in the system? If the game is in development, we can't raise a ticket." | Already solved. The creation screen has an "Application doesn't exist" checkbox that switches the application field to free text. Tell the requester to tick it rather than waiting for the game to be onboarded. |
| "What happens for publishers that do not have a Salesforce record created already?" | There is a generic placeholder account for exactly this. Ask the Salesforce team for it rather than creating a new account, which would pollute the account data. |
| "Where do we leave comments and notes for status updates, internal viewing only?" | The Communication tab on the case — use the Post option, where you can tag people. Chatter on this record type is internal, and it is what the team uses instead of case comments. |
| "So is there no way to view the subtasks in the main Kanban? We were able to do this in Jira." | No. Sub-tasks are a separate object with their own list views, and Salesforce will not nest them under the parent case in a Kanban. Note also that all three sub-task flows are currently inactive, so the Create Sub Task button does nothing (§3). |
| "Do we have a way to flag a 'done' ticket as abandoned?" | Use the standard "Is stopped" checkbox on the case, which was added to the layout for this. It is editable only by the process owners, deliberately. |
| "I'm getting an approval email for cases that are already running." | Almost always correct behaviour rather than a bug. Someone moved the case back to Pending Approval, which re-fires the alert. Check the field history before investigating the flow. |
| "The escalation was supposed to go to leadership and they never got a Slack message." | Working as built. The Slack path only ever resolves one destination and ignores the Team Leader and Leadership checkboxes — those are email-only (§9). Check their inbox before checking the flow. |
| "I received an error when trying to assign ownership of this case" / "when he clicks on the case number his browser does constant redirects." | Both are permission problems, not automation. Check that the user holds one of the three GDRC permission sets and has access to the record type; sharing on this record type is queue-based. |
| "What is the process to get someone added to Salesforce?" | Find "Grow GTM Support Center" in Okta and request permissions there. The GDRC team cannot grant access themselves. |
| "Can you help us delete this ticket?" | Users cannot delete cases. Test and duplicate tickets have to be removed by the Salesforce admin, and this has been a recurring request — consider whether Rejected plus the "Is stopped" checkbox is a good enough answer before deleting anything. |

*Escalation: process design, the service taxonomy and anything that needs a business decision go to Franco Spina, with Nathan TenBoer as cover. Salesforce configuration, stuck records and access go to Yakov Asael. The build history and every past bug are in the private #consulting-salesforce-project channel; the current redesign is in #gdrc-salesforce-process-update; alerts land in #gdmc-salesforce-updates, which still carries the process's former name.*

# 11. Dashboards and reports

**There are none.** A query across every report and dashboard title in the org returns nothing for GDRC, Game Design, Monetization Consultancy, Teardown or Game Audit. The only structured view of this process is the "All Game Design & Revenue Consultancy" Case list view and the three GDRC sub-task list views, and the team works from the Kanban rather than from reports.

That is a real finding, not a gap in this guide. The redesign defines a dashboard as a deliverable — reactive versus planned split, KPI achievement rate, time in each stage — and a separate specification exists for a revenue-attribution dashboard, which defines attribution as starting from the date the ticket was accepted and adds a cross-org influence flag for Create-side impact. Neither has been built. Whoever takes this over inherits both the requirement and a clean sheet.

In the meantime the reporting substitutes are: the case list view for pipeline, field history for stage timings, and the ErrorObject__c records written by the Notifications flow for alert failures. None of them is scheduled or emailed, so nothing in this process alerts anybody about the process itself.

# 12. Related documents

| **Document** | **Type** | **Open this when…** | **Status** |
|---|---|---|---|
| **REQUIREMENTS & DESIGN** | | | |
| [GDRC_Salesforce_Process_Spec_v2.2](https://docs.google.com/document/d/10c7DuH78McCiG-R6_rLCY_AFwBq8nD9HC_N9UBZukOg/edit) | Doc | You need to know what a stage means, why a field exists or what an automation is supposed to do. The single source of business rules — and the only surviving version, despite the revision history referencing a v2.1. | Draft — never signed off; still carries 11 open questions to the Salesforce team |
| [PRD - Game Design and Monetinization](https://docs.google.com/document/d/1ByBy4zj5DdseCOsOapk5K71L00A0wc-S9YQ-Zbtg7oo/edit) | Doc | You hit a field, picklist or object from the first build and need to know why it is shaped that way. Note the typo in the real title. | Superseded by the v2.2 spec |
| [Game Design and Monetinization - Salesforce process](https://docs.google.com/document/d/11GDAiPFVCSNRqO1hGtr9V_qNLDBkh9Vb9yJyDlTdDYM/edit) | Doc | You want the business-side origin story and the original feedback-cadence thinking, including the Jira board this replaced. | Superseded — the requirements doc the PRD was written from |
| **BUILD & IMPLEMENTATION** | | | |
| [GDRC Implementation file - Phase 2](https://docs.google.com/spreadsheets/d/17YEilKUGvW5uZLsDLDNBbucE3fa_FUvlJn2Q1MaDcIY/edit) | Sheet | You need real API names, the spec-stage to picklist-value mapping, or the exact alert day counts behind §8 and §9. The most operationally useful file in this list after the spec. | Current — but four automation rows still say "waiting for answer from Franco" |
| [Game Design and Monetinization - Implementation](https://docs.google.com/spreadsheets/d/1mPgPFPk69vA_mecV2vYSw9CKhN-Iibhzp4D12h7wD9Y/edit) | Sheet | You need the inventory of what was actually deployed in the first build — record types, flows, queues, permission sets, validation rules and the FormTitan forms. | Superseded as design, still the only inventory of the first build |
| [GDRC Mass upload template](https://docs.google.com/spreadsheets/d/1-Lp21IAidG8ARqGnclrjl31qY8ZFh_ZNigMAItxe_oE/edit) | Sheet | You have to bulk-load historic engagements, or you want to see what the old request taxonomy looked like in real data. | Current for its purpose |
| [GDRC Revenue Dashboard Spec](https://docs.google.com/document/d/12ovDGkkLYRDCDcvjr0mB4rnDcCpHhVtd9k-YuPuVEqo/edit) | Doc | You are asked to build the reporting that does not exist yet (§11) — defines attribution start, the cross-org influence flag and a pilot backfill cohort. | Draft — not built |
| **TRAINING & ROLLOUT** | | | |
| [Game Design & Revenue Consultancy - Overview + SF](https://docs.google.com/presentation/d/1CUaqZMPMa3j4dkgX0I9s_RNOe6onkhTDvyWkVq6x4h4/edit) | Slides | Someone asks which clients qualify, or how the team prioritises. Carries the readiness check and the three prioritisation tiers — the only written intake criteria that exist. | Superseded on process; intake criteria still current. Note the trailing space in the real title |
| **CLIENT FEEDBACK** | | | |
| [Client follow-up survey](https://docs.google.com/document/d/1eKXs3VTYqVK6m23AoDSVPoQgmFW3p_sGiAU7s19khbA/edit) | Doc | You need the copy of the published client survey — six sections and roughly 18 questions, including the marketing-consent question. | Current as the client-facing survey. A near-identical "Copy of…" exists — check which is live |
| [GDMC - 90-Day Post-Engagement Client Survey](https://docs.google.com/document/d/1nCqLn4QPuKYSWD2PsHNeshktfC-oIgqKuefgytZlxD0/edit) | Doc | You are asked how impact was meant to be measured after delivery. The only documented mechanism for the KPI achievement rate. | Draft — never signed off, and the flow that would send it is inactive |

*These documents disagree with each other and with the org in ways that will catch you out. The spec's stage names are not the picklist values. The spec asks for a three-question CSAT while all three drafted surveys run to fifteen or twenty. The follow-up interval is a configurable field in the spec, ninety days in one survey doc and one-week-plus-two-weeks in another. There is no mapping between the old Request Type and Client Type taxonomy and the new Category and Proposed Deliverable, so the eighty existing cases cannot be reported alongside anything created from now on. And the per-deliverable flows the spec promises in a follow-on document do not exist, which leaves the smaller engagements — Strategic Teaser and Reduced-Scope Audit — with no documented path at all.*
