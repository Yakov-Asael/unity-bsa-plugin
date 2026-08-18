# GPS

> Source: BSA Process Handbook, tab "GPS". Verbatim.

**GPS**

**Process:** GPS — Global Programmatic Solutions, the team selling exchange inventory to brands, agencies and DSPs · **Built on:** Account hierarchy, Lead, Contact, Campaign, Task, Opportunity and Opportunity Split, with eight flows and a page-layout-driven UI · **Business owner:** Sebastian Diaz Jaramillo, with Michael Marzitelli on account management and Gwen Sparks on the BDR side · **Technical owner:** Dror Diamant (outgoing) → Yakov Asael

*§1–3 what GPS is and how the business works · §4–5 accounts and record types · §6–8 the lead-list intake, account matching and routing · §9 Opportunity Split · §10 troubleshooting · §11 who to ask.*

# 1. What GPS is

GPS stands for Global Programmatic Solutions. It is the team that sells Unity's exchange inventory — ironSource Exchange and Unity Exchange — to the advertising market: brands, the agencies that buy on their behalf, and the demand-side platforms that buy programmatically. It sits inside Grow but it does not look like the rest of Grow, because its customers are advertisers and media agencies rather than game developers.

# 2. Direct and Indirect — the split that explains everything else

GPS sells the same inventory two ways, and almost every design decision downstream follows from which one you are looking at.

| | **Direct** | **Indirect** |
|---|---|---|
| Who Unity deals with | The brand, or the agency running the campaign on the brand's behalf. | A demand-side platform. The DSP buys inventory on the exchange and manages its own relationship with the advertiser behind it. |
| Visibility | Full — Unity knows who is spending and why. | None. Unity sees the DSP, not the advertiser behind it. |
| Relationship | Tailored account management, a close working relationship. | A commercial relationship with the platform. |
| In Salesforce | The account hierarchy in §4 — parent company, agency of record, brand. | A DSP account, referenced from the opportunity through a DSP lookup that includes a "not applicable" option. |

The two exchanges appear as divisions on the records, and the mapping is not obvious from the names:

| **Exchange** | **Division value** | **Note** |
|---|---|---|
| ironSource Exchange (iSX) | Video | The division picklist value predates the exchange branding. |
| Unity Exchange (uX) | UnityAds Brands | Same. |

**One qualification straight from the design doc:** "If the account is only Direct the division does not mean anything." Division distinguishes the two exchanges on the indirect side; on pure direct accounts it carries no meaning, which is why you will find it inconsistently populated.

# 3. The moving parts

| **Piece** | **Name** | **What it does** |
|---|---|---|
| **Flows — note the GPS / GSP spelling split** | | |
| Opportunity creation | GPS - Create new opportunity (screen flow, Active, v7) | The main creation path for a GPS opportunity. The most-iterated piece in the project. |
| Deal linkage | GPS - Update account when deal is created (after save, Active) | Stamps the account when a deal record appears. |
| Lead intake | Lead - GSP Leads Trigger Handler (API name Lead_GPS_Leads_Trigger_Handler, after save, Active, v6) | Handles inbound leads and performs the account matching in §7. Label and API name disagree on the spelling. |
| Contact status | Contact - Update Status GSP Contact (before save, Active) | Maintains the status timestamp used by the ageing logic in §8. |
| Task account fill | Task - Update Account from related contact/lead (Active) | Populates the Account on a task from whatever it is attached to. |
| Support cases | Case - Email Message update GPS case (Active) and Update Case for GPS Support (Active) | Keep the GPS Support case record type in sync with inbound email. |
| **Record types — verified in the org** | | |
| Task | GPS | Drives the GPS Layout and the Type picklist. §5. |
| Campaign | GPS | Every lead-list campaign uses it. §6. |
| Case | GPS Support | The team's own support queue. |
| Event_Meeting__c | GPS | Meetings. |
| Deal__c | GPS | The GPS deal record. |
| **Key fields and components** | | |
| Account | Type (Agency / Brand), Agency_of_Record__c (lookup to Account), Parent Account, Division_Picklist__c, Rating__c repurposed as Target Account, BDR__c | The hierarchy in §4. |
| Contact | Status_GSP__c, Unqualified_Reason__c, Status_Changed_Timestamp__c, Number_Of_Days_In_Current_Status__c, Account_Type__c, GPS_Agency_Id__c, Email_Domain__c, layout New Contact GSP | There is no Contact record type — see §5. |
| Lead | Matched_Account__c and its three formula fields, Division__c, Department_Picklist__c | The matching in §7. |
| Task | Type__c, global action New_Task_GPS, layout GPS Layout | §5. |
| Opportunity | Opportunity Split — two split types, Revenue and Overlay | §9. |
| Lead routing | BDR Queue | §8. |

# 4. The account hierarchy

GPS accounts are three levels deep, and the shape is stated identically by the business and the design document:

**Parent company → Agency of Record → Brand → Opportunity**

| **Level** | **How it is marked** | **What lives there** |
|---|---|---|
| Parent company | The parent account. Account Size Segment distinguishes Holding, Independent and In-House. | The top of the tree — the group that owns several agencies. One parent can gather many agencies underneath it. |
| Agency of Record | Account Type = Agency, with Parent Account pointing at the parent company. Brands point at it through Agency_of_Record__c. | The BDR sits here. Sellers deliberately do not: because an agency can be worked by several sellers across regions, the agreed rule is that agency accounts carry a BDR but not a seller on the account team. |
| Brand | Account Type = Brand, with Parent Account pointing at the agency it is tied to. | The seller sits here. So does the opportunity. |
| Opportunity | On the brand account. | Raised under the brand, not the agency. The reason given is that managed service ties each opportunity to a BI opportunity key, and everything flows back for invoicing and credit management from there. |

**The exception, and it is a common one:** a brand with no agency of record is simply Type = Brand with nothing in the agency lookup. That was decided explicitly, for simplicity.

**Two hierarchy problems you will meet immediately**

  - > **Duplicate agency accounts.** Historical duplicates were never merged. The current cleanup convention is to append "(GPS AOR)" to the surviving record — so when building an opportunity you look for, for example, OMD (GPS AOR) rather than one of the other OMD records. This is a manual, in-progress exercise.

  - > **Brand or agency?** Some names are legitimately both. The working ruling is that the end advertiser is the Brand and the buying entity is the Agency of Record — so Starbucks is a brand, and whoever buys for them is the agency. It is decided case by case and it is a recurring source of duplicate and mis-typed accounts.

A third, unresolved case is recorded in the design doc: a single brand with multiple teams and multiple regions — the Amazon problem — where one account cannot cleanly represent the customer. No decision has been made.

# 5. Record types, layouts and the Contact surprise

**Contact — there is no GPS Contact record type**

**This is worth stating plainly because everyone expects one.** There are no Contact record types in this org at all — not for GPS, not for anyone. What GPS has instead is a dedicated page layout called New Contact GSP and a set of custom fields. Every behaviour people describe as "the GPS contact" comes from that layout plus those fields, and it is applied by profile and by layout assignment rather than by record type. If you go looking for a record type to clone or filter on, there is nothing there.

| **Contact field** | **What it does** |
|---|---|
| Status_GSP__c | The GPS-specific status: New, MQL, Redistributed MQL, Working, Nurture, Qualified, Unqualified. This exists as a separate field precisely because Lead Status is shared across every division in the org and cannot be given GPS-only values. |
| Unqualified_Reason__c | Forced when the status becomes Unqualified: Bad Fit, Bad Info, No Longer with Company. |
| Status_Changed_Timestamp__c and Number_Of_Days_In_Current_Status__c | Maintained by the before-save flow. They drive the ageing rule — a contact sitting in the same status for 30 days is moved to Nurture. |
| GPS_Agency_Id__c | Ties the contact back to its agency. |
| Account_Type__c, Account_Name_Formula__c, Email_Domain__c | Convenience fields for the BDR list views and for matching. |

**Task — a record type that exists mainly for one picklist**

The Task record type GPS drives the GPS Layout and, above all, the Type picklist that the BDR team is measured on:

*Other · Email · InMail · Call · Meeting booked · Meeting Completed (paid on) · BDR Meeting Completed (paid on)*

The two values marked "paid on" are the ones that matter commercially — they are what BDR compensation reads. Task status runs Backlog, Not Started, Pending, In progress, On Hold, Completed, and the Account is filled in automatically from the related contact or lead.

**The known defect:** the correct Type values only appear on tasks created through the New_Task_GPS global action. A task created any other way — from a list view, from an activity timeline, from another layout — lands on a different record type and shows a different Type picklist. Users report it as "the dropdown is different on these two tasks", and they are right. The root cause was never chased down. When someone reports it, the first question is where they created the task from.

**The other three record types**

Campaign GPS is used by every lead-list campaign (§6). Case GPS Support is the team's own support queue, kept in sync by two flows. Event_Meeting__c GPS covers meetings. None of them carry surprises.

# 6. The lead-list intake

GPS runs events and buys lists. The recurring ask is: here is a spreadsheet of people, please create them as leads, create a campaign, and connect them to it. This is one of the most frequent requests the team makes of Salesforce, and it is worth being honest about how it works today.

**There is no automation, no case type and no form.** A BDR posts a message in the GPS Salesforce channel with a Google Sheet link and a campaign name. Someone on the Salesforce side loads it by hand. Every time.

A representative request, verbatim: "can we please upload these contacts as leads under campaign 'Horizon Media event FY26' and have them assigned to me". The reply is a link to the created campaign and a note that the leads were connected to it.

**The list format — the only written spec that exists**

This mapping comes from the implementation tracker and is what the loader works to. Getting the required columns right is the difference between a load that takes ten minutes and one that bounces back.

| **Column** | **Field** | **Required** | **Note** |
|---|---|---|---|
| **Lead** | | | |
| First Name | FirstName | Yes | |
| Last Name | LastName | Yes | |
| Email | Email | Yes | Also the practical dedup key. |
| Company Name | Company | Yes | |
| Job Title | Title | Yes | |
| Country | CountryCode or Country | Yes | Depends which you are passing. |
| Division | Division__c | Yes | iSX loads as Video; uX loads as UnityAds Brands. |
| Department | Department_Picklist__c | Yes | Defaults to Advertiser. |
| Lead Source | LeadSource | Yes | Always Events Campaign for these loads. |
| Phone | Phone or MobilePhone | No | |
| App URL | App_URL_from_form__c | No | |
| **Campaign Member** | | | |
| Campaign | CampaignId | Yes | The campaign the list belongs to. |
| Status | Status | Yes | Attended, Connected, Registered, Approved, Rejected, Sent, Responded, New, Signed Up, Converted. |
| Lead / Contact | LeadId or ContactId | — | Populated if an existing lead or contact was found. This "if found" test is the only deduplication rule written down anywhere. |

**What actually got loaded**

Twenty-one GPS campaigns exist; ten carry members. The manually loaded ones dominate by volume:

| **Campaign** | **Leads** | **Type** | **Loaded by** |
|---|---|---|---|
| [Cannes 2026](https://ironsrc.lightning.force.com/lightning/r/Campaign/701Qv00000euzbfIAA/view) | 559 | Seminar / Conference | Dror Diamant |
| [OMG Breakfast NYC 2026](https://ironsrc.lightning.force.com/lightning/r/Campaign/701Qv00000hPm3JIAS/view) | 156 | Other | Dror Diamant |
| [Openmarket 2026](https://ironsrc.lightning.force.com/lightning/r/Campaign/701Qv00000h9mBEIAY/view) | 111 | Seminar / Conference | Yakov Asael |
| [Horizon Media event FY26](https://ironsrc.lightning.force.com/lightning/r/Campaign/701Qv00000i1QQeIAM/view) | 65 | Seminar / Conference | Dror Diamant |
| us-event-Cannes-2026-GPS-VIP Lunch | 58 | Seminar / Conference | Marketing |
| us-event-Cannes-2026-GPS-Direct and -Indirect | 10 each | Seminar / Conference | Marketing |

# 7. Matching a lead to an existing account

When a lead arrives, GPS does not want the BDR to go hunting through the account hierarchy to work out who the person belongs to. A process runs on the lead and tries to identify the agency or brand already in Salesforce, then records the answer on the lead so the BDR can see it at a glance and so conversion has somewhere to go.

**What the design says**

The design document is short and specific. Under Lead automation:

*"Find if an existing Agency or a Brand are already in the system by using: 1. Client name 2. Domain 3. Website. If found bring info on that account."*

*And under Lead Conversion: "If found account suggest it as a convert to account."*

**Read that carefully — it is a suggestion, not a link.** The matched account is a hint for the human. It does not attach the lead to the account, it does not change ownership, and it does not force the conversion target. The BDR is still free to convert into a different account, or to create a new one. Nothing enforces the match.

**What actually runs**

| **Piece** | **Detail** |
|---|---|
| The flow | Lead - GSP Leads Trigger Handler, API name Lead_GPS_Leads_Trigger_Handler. Record-triggered on Lead, after save, Active, version 6. |
| Where the answer is stored | Matched_Account__c on Lead, a lookup to Account. It is a plain lookup — nothing else changes when it is set. |
| The three read-only companions | Matched_Account_ID__c, Matched_Account_Name__c and Matched_Account_Owner__c are formula fields that reach through the lookup to the account's long Id, its name and its owner. They exist so that list views and reports can show the matched account without a join, and so a BDR can see straight away who already owns the relationship. |
| Where a BDR sees it | Both GPS lead list views — All Open GPS Leads and Unassigned Open GPS Leads — carry Matched Account as a column, sitting next to Company. The unassigned view is filtered to the BDR Queue, so the matched account is the first signal a BDR gets when picking work up. |

# 8. What happens to a lead after it lands

New leads go to a queue rather than to a person. The rule as launched: every new lead is assigned to a queue called BDR Queue, and BDRs pull from it based on their capacity and territory. The intended second phase — routing by territory, falling back to the BDR lead where a territory has nobody assigned — is designed but not built.

A legacy workflow that routed brand leads to a single named person still exists alongside this. Check which one fired before assuming the queue is the only path.

**The status model**

Leads and contacts share a vocabulary but not a field. Lead Status is org-wide and shared with every other division, so GPS cannot add values to it; Contact carries the GPS-specific Status_GSP__c instead. The values are New, MQL, Redistributed MQL, Working, Nurture, Qualified and Unqualified, with a mandatory reason when Unqualified. A contact that has not moved for 30 days is pushed to Nurture automatically.

On conversion, the matched account from §7 is offered as the account to convert into. It is a suggestion the BDR can override.

# 9. Opportunity Split

GPS deals are frequently worked by more than one seller, and the org previously had no way to represent that. Opportunity Split was enabled for exactly this reason. Note that it is an org-wide platform feature, not a GPS-only one — turning it on affected every opportunity in the org, which is why it took two attempts and a Salesforce support case to deploy.

**The two split types**

| **Type** | **Totals to 100%?** | **What it is for** |
|---|---|---|
| Revenue | Yes — enforced. Salesforce blocks the save if the splits do not add up. | Quota and commission credit. This is the one that feeds pipeline, forecast and revenue reporting. Splitting it is how you divide credit for the deal between sellers. |
| Overlay | No — not validated. | Recognising contribution without duplicating revenue. For sales engineers, managers and partners. Tracked entirely separately from Revenue. The guardrail given at launch: an overlay is not double credit, so do not use it to duplicate revenue credit for the same dollar. |

**What happens by default**

Every opportunity gets a Revenue split at 100% on its owner, created automatically. A backfill ran across existing pipeline, so every historical opportunity already has one. Nothing needs to be done for the normal single-owner case.

**The part that is not automatic:** if an opportunity has genuinely been worked by two people, someone has to add the second seller as an opportunity team member and create their split by hand. The backfill could not know about arrangements that only existed in someone's head.

**Two constraints that catch people out**

  - > **Only the Opportunity Owner can manage the team or the splits.** No one else can add a team member or create a split, regardless of their role or profile. To let anyone else edit the opportunity at all, the owner has to add them as a team member with Write access — that team membership is what grants the edit right, and there is no other route to it.

  - > **Changing the owner wipes the splits.** If the Opportunity Owner is changed, every existing team member and split record is deleted and the system resets to a single team member and a single 100% split on the new owner. Any split arrangement that existed before the ownership change is gone, silently. Reassigning an opportunity therefore means rebuilding its splits afterwards, and nothing warns you.

**Reporting:** a report exists showing how every opportunity breaks down across team members — . Every opportunity appears in it, including ones nobody has ever split, because of the default 100% record.

# 10. Troubleshooting

**"The invoice went to the brand, but the agency pays"**

The most frequently raised problem on GPS accounts, and it is a consequence of the hierarchy rather than a bug. Invoices are created against the account related to the opportunity's BI opportunity — and the opportunity sits on the brand (§4). So by default the brand gets billed, even though the agency or parent company is the paying party.

The configuration that fixes it, per account:

**1.** On the brand account, set Invoiced with to point at the agency.

**2.** On the agency account, set One invoice per — All produces one combined invoice across the agency's brands, Account produces a separate invoice per brand. The default is separate.

This has to be done per account and nothing prompts for it at account creation, which is why it keeps recurring. It is an open item.

**"The dispute has no approver"**

Specific to accounts managed by the GPS account management team: the approver setup for those accounts was never configured. The root cause is known and the question — who approves disputes on GPS-managed accounts — has been asked and not answered. Until it is, these disputes need an approver adding by hand each time.

**Other known failures**

| **Symptom** | **Cause** |
|---|---|
| A lead is matched to "Test advertiser isx workday" | The automatic matching in §7. Currently affects nearly every inbound web lead that gets matched at all. Treat the value as unreliable until the flow is fixed. |
| A task shows the wrong Type values | Created outside the New_Task_GPS global action, so it is on a different record type. §5. |
| Several accounts exist for the same agency | Historical duplicates, being consolidated by hand with "(GPS AOR)" appended to the survivor. §4. |
| A brand account has no BDR even though its agency does | BDR is populated on agency accounts. Inheriting it down to brands was requested and is not implemented. |
| Fields are missing from a lead or contact page | Layout assignment, not permissions. The same user can see different fields depending on which layout applies, and at least one report of this was never fully closed. |
| A GPS opportunity is on the agency, not the brand | Wrong by convention but not blocked by anything. It will make forecasting and invoicing harder downstream. |

# 11. Who to ask, and what to read

| **Topic** | **Person** |
|---|---|
| The GPS Salesforce roadmap and priorities | Sebastian Diaz Jaramillo. Runs the recurring GPS sync and owns the roadmap. |
| Account management, invoicing, the hierarchy in practice | Michael Marzitelli. Also the loudest and most useful reporter of what is broken. |
| BDR process, lead lists, statuses, task types | Gwen Sparks. Originates most of the requirements in §5 to §8. |
| Account hierarchy cleanup and the AOR consolidation | Adam Kadet. |
| Sales leadership and the split requirements | Chris Feo, Chris Jerome, Drew Bassler, Melissa Jensen. |
| Layouts, list views and enablement | Ryan Amante. |
| The Salesforce build | Dror Diamant (outgoing) → Yakov Asael, with Amir Weingrod on the design. |

**The documents worth reading, in order**

| **Document** | **Why** |
|---|---|
| [PRD/TDD - GPS Team - Direct/in Direct Accounts MGT](https://docs.google.com/document/d/1tJgwOSDFEK0KOFhrfy167LR_Y6iTOQLp6I6ySpyOKkk) | The master document. The data model, the account types, the creation paths, the Phase 2 lead automation spec behind §7, the field mapping section and the open questions. Start here. |
| [GPS - Direct/Indirect (deck)](https://docs.google.com/presentation/d/13qMNHsxgPSJbjB129RLmtPCdMwB1zqpy0ZI5TzUv62o) | The clearest explanation of what a DSP is and why direct and indirect are structurally different. Read it before the PRD if the business is new to you. |
| [GPS BDR Salesforce Implementation](https://docs.google.com/spreadsheets/d/1v1AqdqsiiyppiF7YXKcb3loRXLYv6KHdYodTMUFSDnY) | The build tracker — exact record type, field, flow, layout and queue names, plus the lead and campaign-member intake mapping reproduced in §6. |
| [GPS BDR Salesforce Requirements](https://docs.google.com/spreadsheets/d/15E4UrkPOFF53bB-fGFcGdGfGDjHuBGEh3qUj3aa52wQ) | The numbered requirements behind the Task, Contact and Lead work. |
| [GPS BDR Salesforce FY26](https://docs.google.com/document/d/1U9AhxeiAu1lMiuHx8sAL0hwOKHNAbGA-PsyQYtLC7Wg) | The BDR side in the team's own words, with critical versus nice-to-have marked. |
| [Roadmap for GPS Salesforce](https://docs.google.com/document/d/19rcnYBfni5Bdla-jUC7KyzldrL4S0ubt33rE-cC-e0I) | What was planned, quarter by quarter. |
| [Opportunity Split — Sales Enablement (deck)](https://docs.google.com/presentation/d/1F4bXgQNGllqbuHhGOo8XgSnY5d29uwz_3fpdYnK2Q0I) | The material the sellers were trained on. Use it verbatim rather than re-explaining splits. |
| [Lead, Contact and Task training (deck)](https://docs.google.com/presentation/d/194CO57ZoNurhmkXbovkptNCMaC6C0tu_przhZiTfzyQ) | What the BDRs were shown when the queue and the statuses went live. |
