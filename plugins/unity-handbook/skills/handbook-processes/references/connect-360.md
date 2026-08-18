# Connect 360

> Source: BSA Process Handbook, tab "Connect 360". Verbatim.

**Connect 360**

**Process:** Connect 360 — users say "C360" or just "ticket" · **Object:** Performance_Manager_Request__c, labelled "Connect 360" · **Date:** 10 August 2026 · **Business owner:** Rotem Yosef, Morag Nadel · **Technical owner:** Dror Diamant → Hagar Itzhak

*§1–3 how the process works · §4–8 how it is built · §9 troubleshooting · §10–11 where to look next.*

# 1. What this process does

A Connect 360 is a request for performance help on one advertiser or publisher account — a drop investigation, a benchmark, a QBR, an optimisation, a proactive check. An Account Manager raises one when a client has a performance problem the AM cannot answer alone; a Performance Manager raises one proactively against their own book. It exists so that this work is owned, visible and measurable instead of living in Slack threads. Roughly half of all requests are created from Slack rather than from Salesforce, which is unusual for this org and shapes almost everything about how the process behaves and how it fails.

**Lifecycle**

**1.** A request is raised: an AM reacts to a message in a Slack channel with the emoji, one of the Centro actions, or anyone uses the Create Connect 360 Form global action in Salesforce.

**2.** Connect 360 - Actions on creation routes it. External Slack requests go straight to the Performance Manager named on the form. Salesforce and internal requests go to the Team Leader looked up from PerformanceManagerRequestTL__c on Region plus Product. Status__c = "Backlog" and the Team Leader becomes the owner.

**3.** The Team Leader assigns a Performance Manager, from the Assign button in the Slack notification or in Salesforce. Status__c = "Assigned", ownership moves to the PfM, and Assigned_Timestamp__c is stamped.

**4.** The PfM works it. Status__c = "In Progress", or "Pending" and "Pending Client or AM" while waiting on someone else.

**5.** The PfM closes the ticket and moves it to "Done".

# 2. Where records are created, and how they reach their target

| **Entry point** | **How it works and what to know** |
|---|---|
| Client Slack channel → :pfm111: emoji reaction | The external path, and the one the business designed the process around. An AM reacts to the client's message; the Centro app opens a short form; all fields on it are mandatory; the AM picks the Performance Manager directly. APAC uses a different emoji, :performance_:. |
| Centro Actions | From the Centro app, users can open a creation form. Four forms exist: EMEA Ads, EMEA TJ Supply, EMEA TJ Demand, APAC. Which one a user gets, and what each writes back to Salesforce, is covered in §3. |
| Salesforce → Create Connect 360 Form global action | The full form, and the largest single source at 769 of 1,589 records. Created by a PfM it assigns to the creator; created by an AM it routes on Region and Product. Note the form asks for the team first, EMEA or APAC, which sets the record type. |
| BLOCKED — creating from the object's New button | Cant_create_connect_360_from_new_button exists to force people through the global action, because a record created any other way has no Request Source and never routes. It reads as inactive in the metadata snapshot — verify in Setup. |

**How a request reaches a Performance Manager**

  - > Nothing about routing is a queue-based assignment rule. It is a custom-setting (PerformanceManagerRequestTL__c) lookup inside a flow, on Region plus Product, returning one named Team Leader and one Slack channel.

  - > The Team Leader is an interim owner only. The record sits at Backlog under their name until they assign a PfM.

  - > An AM cannot assign a Performance Manager from Salesforce — only from the external Slack form, where they pick the PfM themselves.

  - > The Centro app must be installed in the Slack channel and the user must have logged into Salesforce from Centro. If either is missing, the emoji does nothing at all and no error is shown.

  - > If creating a channel to get Centro notifications into it, the Centro application must be added to the channel.

  - > There is no link back from the record to the Slack thread it came from. Only the channel is captured, which is why a request cannot always be traced to its conversation.

# 3. The two record types

Connect 360 has two record types, EMEA Team and APAC Team, and they are not two skins on the same form. They differ in how the request is assigned, in which picklist values exist, and in which Centro form creates them. Record type is chosen at the moment of creation and is never changed afterwards, so a request raised on the wrong one has to be recreated rather than corrected.

| | **EMEA Team** | **APAC Team** |
|---|---|---|
| How the record type is set | The Salesforce global action asks "Please select your team" on its first screen. Choosing EMEA opens a second screen where the fields shown depend on Product — Campaign ID and Advertiser Imply Link for uAds, Ad set / Offer ID for TJ Demand, Publisher app ID for TJ Supply. | Choosing APAC keeps everything on the first screen. Subject, Details, App Bundle Name, Campaign ID and Time Frame appear only for APAC. |
| Who the request is assigned to | Routed through PerformanceManagerRequestTL__c on Region plus Product to a named Team Leader, who owns it at Backlog until a Performance Manager is assigned (§6). | Assigned to the APAC OWP team queue. Connect 360 - Actions on creation sets the owner to a hardcoded queue ID, 00GQv00000B7zWf, rather than looking it up — the routing matrix has no APAC rows at all. |
| Status values | Backlog · Assigned · In Progress · Pending · Done | The same list without Backlog. An APAC request never sits in Backlog, so the Backlog-based list views and the "days from Backlog to Assigned" measure are always empty for APAC. |
| Region | EAST EMEA · WEST EMEA · INSEA | APAC China · APAC Japan · APAC Korea. No Region value is shared between the two record types. |
| Product | uAds · TJ Demand · TJ Supply | TJ Demand · TJ Supply. |
| Network | iAds · uAds · iAds and uAds · TJ · TJ Demand | TJ · TJ Demand only. |
| Task Type — the reporting field | 15 values | 6 values. Only Benchmarks & Best Practice and QBR appear on both, which is a fair summary of how differently the two teams work. |

**Worth knowing before you change anything:** Connect 360 - Actions on creation branches on hardcoded 18-character record type IDs rather than on the record type name, and the APAC branch also carries a hardcoded queue ID. Cloning this process for a third region means editing the flow, not adding configuration.

**The four Centro creation forms**

Centro does not present one form. EMEA has three, chosen by the account's division and department, and APAC has its own. Each form writes to its own Task Type field rather than to the main one.

| **Centro form** | **Task Type field it writes** | **Values on that field** |
|---|---|---|
| EMEA Ads | Task_Type_EMEA_Ads__c | Benchmarks & Best Practice · Campaign is not reaching ROAS target · Creatives analysis · Drop Investigation · General account review · QBR |
| EMEA TJ Demand | Task_Type_EMEA_TJ_Demand__c | Bid/GEO recommendations · Blocklist/Allowlist · Creatives analysis · Event flow / campaign setup analysis · Low conversion rate · Per app bidding · QBR |
| EMEA TJ Supply | Task_Type_EMEA_TJ_Supply__c | Benchmarks & Best Practice · Geo Multiplayer · Placements · QBR · Segmentation · eCPM drop |
| APAC | Task_Type_APAC__c | Benchmarks & Best Practice · Event Structure Analysis · Other · Performance Analysis · Performance Issue Investigation · QBR |

**How four Task Type fields become one**

None of those four fields is what the process reports on. Task_Type__c is. Connect 360 - Run Flow fires whenever the record is created or a Task Type changes, and recalculates Task_Type__c with a formula that takes the first of the four that is not blank, in this fixed order: EMEA Ads → EMEA TJ Demand → EMEA TJ Supply → APAC, falling back to whatever Task_Type__c already held. So the Centro forms capture, and the flow consolidates.

  - > Report on Task_Type__c and nothing else. It is the field every report, list view and the Connect_360_Follow_up_required__c custom setting reads. The four form fields are capture only.

  - > Editing Task_Type__c by hand does not stick. The next save recalculates it from whichever form field holds a value and overwrites the edit.

  - > The order is fixed, not contextual. If two form fields ever hold a value on the same record, EMEA Ads wins and APAC is ignored. Nothing checks that the field being read matches the record's record type.

  - > All four form fields carry values on both record types, so nothing prevents an APAC record from being written by an EMEA field, or the reverse.

  - > Task_Type__c is a dependent picklist controlled by Product__c, but the four form fields are not dependent on anything. The flow can therefore write a Task Type that is not a valid pairing for the record's Product — the most likely explanation when a task type looks wrong in reporting.

# 4. The flows — what each does and what triggers it

Four active flows and no Apex. Two carry the whole process: Connect 360 - Actions on creation does the routing and every notification, and Connect 360 - Run Flow manages status and timestamps. Two further flows that drive follow-up are switched off.

| **Flow** | **Trigger** | **What it does** |
|---|---|---|
| **CREATION** | | |
| Create_Performance_Manager_Request | Screen — "Create Connect 360 Form" global action | When a user opens the global action, it asks which team they are on, EMEA or APAC, collects the account and request detail on a second screen, attaches any files as ContentDocumentLinks and creates the Connect 360 record. This is the only path that sets Request_Source__c = "Salesforce". |
| **ROUTING, STATUS AND NOTIFICATIONS** | | |
| Performance_Manager_Request_Actions_on_creation | Connect 360, after save on create and update, when Run_Flow__c = TRUE, or the status is "In Progress", or the status is "Follow Up" with no AM follow-up notification yet | The engine of the process. It looks up the Team Leader from PerformanceManagerRequestTL__c, sets Status__c to "Backlog" or "Assigned", moves ownership to the Team Leader, the Performance Manager or the APAC OWP team queue, stamps Backlog_Timestamp__c and Assigned_Timestamp__c, writes the Kanban subject, posts the status emoji back onto the originating Slack message, and fires every Centro message and email in the process. Version 92 — by far the most edited thing here, and the first place to look when anything routes or notifies incorrectly. |
| Performance_Manager_Request_Run_Flow | Connect 360, after save on create and update, when the record is new or Task Type, Performance Manager, Status or the impact fields change | Keeps the two status fields in step and stamps the stage timestamps — In_Progress_Timestamp__c, Moved_to_follow_up__c, Done_Timestamp__c and Follow_Up_Timestamp__c — then sets Run_Flow__c = TRUE to hand over to Actions on creation. It also consolidates the four Centro Task Type fields into Task_Type__c (§3), so a task type edited by hand can be overwritten. |
| Connect_360_Check_run_flow_to_send_AM_notifications | Scheduled | Sweeps records to trigger the AM-facing notifications that Actions on creation sends — the "your request moved to follow up" and "did you send the client the outcome" chasers, which escalate on AM_Notification_Counter__c. Not present in the metadata repo snapshot; confirm its schedule in Setup. |
| **INACTIVE — BUT STILL WIRED UP** | | |
| Connect_360_Fill_Follow_Up_fields | Screen — the "Follow Up" quick action on the record | This is the flow behind the Follow Up button. It writes Request Impact, Revenue Impact and the notes, stamps Follow_Up_Timestamp__c and sets Status__c = "Done". The quick action still points at it and it is inactive in the org. |
| Performance_Manager_Request_Follow_Up | Scheduled | The follow-up reminder sweep — the mechanism behind "notification on the follow-up date, and again two days later". Also inactive. |

# 5. Approval processes

None found. Connect 360 has no approval process and no approval step of any kind — a request is routed and assigned, never approved. Progress is controlled entirely by Status__c and by who owns the record. If someone describes a Connect 360 as "waiting for approval", they mean it is sitting in Backlog waiting for a Team Leader to assign a Performance Manager.

# 6. The routing matrix

There is no approver matrix, but there is a routing matrix, and it works the same way and fails the same way. When a request is created from Salesforce or an internal channel, the flow looks up PerformanceManagerRequestTL__c — a list custom setting — on Region plus Product, and stamps the Team Leader and the Slack channel onto the record. The value is stamped at creation and never re-resolved, so a request routed to the wrong team stays wrong until someone reassigns it by hand. Requests raised from a client Slack channel skip this entirely: the AM picks the Performance Manager on the form. Changing who receives a team's requests is a custom-setting change, not a code change.

# 7. Other mappings in the process

| **Source** | **Target** | **When and why it matters** |
|---|---|---|
| PerformanceManagerRequestTL__c (list custom setting) | Team Leader, TL email list and Slack channel on the record | The single point of failure for routing. A missing Region plus Product combination means no Team Leader is stamped and the request sits unowned in Backlog. |
| The four Centro Task Type fields | Task_Type__c, consolidated by Connect 360 - Run Flow | First non-blank wins, in a fixed order, with no check against the record type or the Product dependency (§3). This is where a wrong-looking task type comes from. |
| Task_Type__c → the timestamp fields | Backlog, Assigned, In Progress, Moved to follow up, Done, plus the two elapsed-days formulas | These are the only measurement the process has — days from Backlog to Assigned, and Assigned to Follow Up. They are also what the analysis dashboard on the wishlist was meant to use. |

# 8. Notifications

| **Notification** | **Trigger** | **Recipients** | **Channel** |
|---|---|---|---|
| New request needs assigning | Record created and routed to a Team Leader | The team's Slack channel from the routing matrix | Slack via Centro — carries creator, account, region, product, task type and subject, with an Assign button |
| Assigned to you | A Performance Manager is set on the record | The Performance Manager | Private Centro message with Update Status and Follow Up buttons, plus an email alert |
| Team Leader chaser | Request still unassigned | Team Leader | Slack via Centro |
| Did you send the client the outcome? | AM notification counter reaches its second and third step with the answer still No | The Account Manager | Centro message |
| Status emoji on the original message | Status changes to In Progress or Follow Up | Everyone in the client Slack channel, including the client | Slack reaction posted back onto the original message — the only client-visible part of this process |

# 9. FAQ

**Check these five first:** (1) Is Performance_Manager__c populated, and is it the person complaining? (2) What is Status__c, and does Status_No_follow_up__c agree with it? (3) Is Follow_Up_Timestamp__c empty? (4) Does the Task Type have a row in Connect_360_Follow_up_required__c? (5) Was it created from Slack or Salesforce — Request_Source__c tells you which half of the process to look in.

| **Symptom, in the user's words** | **Cause and fix** |
|---|---|
| "The 'follow up' button to be able to move the ticket to Done isn't available." | The button only appears when you are the assigned Performance Manager, the status is "Follow Up", and the follow-up date is today or earlier. The usual cause is that Performance_Manager__c is empty — assign it and the button appears. Note the flow behind the button is currently inactive (§4), so check that too. |
| "The team is having trouble moving tickets from follow up to complete. Could you take a look and advise what we are doing wrong?" | Follow_Up_Timestamp__c is null, which means the follow-up was done by editing the fields rather than through the Follow Up button or the Centro message. Only those two paths stamp the timestamp. Re-do it through the button. |
| "Why can't I move the card to Done when the Follow Up tab fields are already filled?" | Same cause, different phrasing. Filling the fields is not the same as completing the follow-up. The design deliberately blocks a manual move to Done and sets it automatically once the follow-up is recorded properly. |
| "My team select 'My connect 360' and see tickets that are not assigned to them." | Working as designed. That list view shows records where the user is the Performance Manager plus records still owned by the queue that the user is a member of. When the status is Backlog a team member sees their team's unassigned records so someone can pick them up. |
| "An emoji did not trigger Centro ticket creation." | Three things to check in order: is the Centro app installed in that Slack channel; has the user logged into Salesforce from Centro, using the Salesforce setup button in the app; and is it the right emoji for their region — EMEA uses :pfm111:, APAC uses :performance_:. Nearly always the login. |
| "We are getting an error alert when trying to open ticket through Centro." | A dependent-picklist mismatch. Task Type depends on Product, so if the Centro form does not carry the field that the dependency needs, the form fails. If a new dependency has just been added in Salesforce, the external form has to be updated to match. |
| "The task type on this ticket is not one we would ever pick for that product." | The four Centro forms each write their own Task Type field, and the flow copies the first non-blank one into Task_Type__c without checking it against the record type or the Product dependency (§3). Correct Task_Type__c on the record, then clear the form field that is feeding it, or the next save will overwrite you again. |
| "For tasks that don't require a follow-up, is it possible to not have to add a follow-up date?" | Yes, and it is already built. Connect_360_Follow_up_required__c decides per Product and Task Type. Benchmark and Trend Analysis and Set up & Workflows are set to no follow-up; Drop Investigation, Optimizations, Proactive Check, QBR and Launch all require one. Add the row to the custom setting for a new task type. |
| "I had to reassign this ticket — I'm not sure how it ended up being assigned to me in the first place." | The routing matrix stamped the wrong Team Leader for that Region and Product combination (§6). Reassign the record by hand, then fix the row in PerformanceManagerRequestTL__c so the next one routes correctly. Existing records are never re-routed. |
| "The OW team doesn't get the Slack notifications." | Either the routing matrix has no row for that Region and Product, so no channel was stamped, or Centro is not installed in the destination channel. Adding Centro to a channel is the PfM team's own responsibility, not the Salesforce team's. |
| "Three notifications were sent but in Salesforce we only saw two tickets — and we couldn't see which thread was which." | A known and unresolved limitation. The record captures the Slack channel but not the thread, so a request cannot be traced back to its conversation. There is no workaround; searching the channel by timestamp is the only route. |
| "Her view of the ticket seems different from mine — can you check that she has full access?" | The object is Read/Write org-wide, so differences come from profile or permission-set field-level security, not sharing. Compare the two users' permission sets before looking at anything else. |
| "The Subject field doesn't always get displayed on the tile even when it's filled out." | The Kanban shows Subject_Kanban__c, a separate field written by the flows, not the subject the user typed. If the flow did not run, the tile is blank. Several of the oldest stuck records have blank tiles, which is plausibly why nobody ever worked them. |
| "Is Connect 360 the general name of the platform, or the name of our form?" | It is the name of the form and of the Salesforce object — the object's API name is Performance_Manager_Request__c, which is why the two names appear interchangeably in URLs, list views and reports. Unrelated to Customer 360, and unrelated to the Gainsight C360 used elsewhere at Unity. |

*Escalation: process design, field changes and anything that needs a business decision go to Rotem Yosef, who is the approver for changes to this process. Team-level questions go to the relevant team lead — Edona Mulaku for Demand Video, Tatiana Ventsova for Supply Video, Ido Levy for OW. Salesforce configuration and stuck records go to Yakov Asael. Change requests are collected in the wishlist sheet (§11) rather than in a ticket queue.*

# 10. Dashboards and reports

| **Dashboard** | **Folder** | **Who uses it** | **Still trustworthy?** |
|---|---|---|---|
| [Connect 360 - CRMA Dashboard](https://ironsrc.lightning.force.com/analytics/dashboard/0FKQv0000000X8rOAE) | Connect 360 | PfMs, Guy Shaked, Adi Norman | Yes |
| [Connect 360 Dashboard](https://ironsrc.lightning.force.com/lightning/r/Dashboard/01ZQv000002ig7FMAQ/view) | Connect 360 | Team leads — volume, source, task type, ageing and past-due follow-ups | Stale — its reports have not been run since the volume decline; the Product breakdown is wrong (§7) |

*The "Connect 360 Dashboard" folder is the real unit of ownership — nine of the sixteen reports live there and they are what the dashboard is built from. None of them is scheduled or emailed, so nothing in this process alerts anybody automatically. Given the state of the follow-up backlog, a scheduled subscription on the Past Due report would be the cheapest possible improvement.*

# 11. Related documents

| **Document** | **Type** | **Open this when…** | **Status** |
|---|---|---|---|
| **REQUIREMENTS & DESIGN** | | | |
| [Growth Performance Requests DD](https://docs.google.com/document/d/1rfWAxhFOYIoEe5Nou2c3RLOP16r3L7LyI-_0_q7mMjs/edit) | Doc | You need the original build spec — the field list, the picklist values, the owner-assignment logic and what each status is supposed to mean. The only design document that exists. | Current, but its "Validations" section was left empty — no validation rule was ever specified in writing |
| [Connect 360 Process for PM](https://docs.google.com/spreadsheets/d/1ehL2D3VLF7ZK86ySbijqGt3R2GflSReJMmwws_k01zk/edit) | Sheet | The question is about APAC. This is the Offerwall APAC team's requested variant — different regions, different products, different task types, a queue instead of a named owner. | Draft — a set of open requests and unanswered questions, largely not built |
| **MATRICES & MAPPINGS** | | | |
| [TL Mapping](https://docs.google.com/spreadsheets/d/1Z24VPdTZWHjxmEy1OBRh4H17WBSp-yM6YRGcoa_wKqo/edit) | Sheet | A request went to the wrong team lead. This is the Region plus Product to Team Leader and Slack channel table behind the routing, with the real user IDs and channel IDs. | Current — the live mapping, nine rows |
| [Demand iAds/uAds Connect 360](https://docs.google.com/presentation/d/1aUBnGJhHy6hoCN2ID-n9Y_Tsj3Jdu7BJ9CDfXS3SzlM/edit) | Slides | You need the authoritative answer to "does this task type need a follow-up?" It supersedes the task-type list in the design document. | Current — and it overrides the DD on task types |
| **TRAINING & ROLLOUT** | | | |
| [Connect 360_PfMs](https://docs.google.com/presentation/d/1n_yzxb7B0z9CGynNhIR0EEYYo7ZSbmnAaQ-e3OGiKSY/edit) | Slides | You have to explain the process to an AM or a new PfM. The end-user enablement deck — how to create, get notified, assign and follow up, from both Slack and Salesforce. | Current — the operational how-to, though unsigned |
| **BACKLOG** | | | |
| [Connect 360 - Wishlist](https://docs.google.com/spreadsheets/d/1v1oYGefZonaxzPLQR-eD8Zj-B53S1eOKidLrt3w9YnE/edit) | Sheet | A stakeholder asks whether something was ever requested. This is the change-request mechanism for the whole process — there is no ticket queue for Connect 360 changes. | Draft — no owners, no due dates; two items still open |

*Six documents, and they disagree with each other in ways that matter. The task-type list differs three ways between the design document, the Video deck and the APAC sheet — treat the Video deck as authoritative for EMEA and INSEA. The design document lists seven statuses; APAC asks for a status called "Finish" that exists nowhere. No SLA is defined anywhere, and no validation rule is documented at all. There is no TDD, no go-live plan and no QA document.*
