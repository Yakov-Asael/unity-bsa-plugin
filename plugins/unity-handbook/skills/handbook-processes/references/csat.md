# CSAT

> Source: BSA Process Handbook, tab "CSAT". Verbatim.

**CSAT**

**Process:** CSAT — the customer satisfaction rating on support cases · **Built on:** Case, one record-triggered flow, two email alerts, four email templates, an external FormTitan form and one Lightning web component · **Business owner:** Shani Kovalsky · **Technical owner:** Dror Diamant → Neta Ronen

*§1–2 what it is and where it lives · §3–8 how it is built · §9 reporting · §10 troubleshooting · §11–12 watch-outs and who to ask.*

**Read this first.** The emoji in the email are not a Salesforce component. They are five images, each wrapped in an ordinary hyperlink to an external page hosted by FormTitan. Salesforce does not know the customer clicked anything until FormTitan calls back into the org. So when a rating is missing, the question is almost never "which flow failed" — it is "did the link fire, and did the callback land". Debugging starts at the URL, and §3 is where that URL is taken apart.

# 1. What this process does

Every time support emails a customer, the bottom of the message carries a row of five emoji — from a broad smile to a scowl — under the line "How satisfied are you with our support?". Clicking one is the whole rating. The customer does not fill anything in, does not log in, and does not come back to Salesforce; one click is enough to record a score against their case. A page then opens offering three optional follow-up questions, and if they answer those too, more fields fill in.

Because everything lands on the Case record rather than in a separate survey tool, CSAT is reportable next to record type, owner, team, product line and resolution time — which is the reason it was built this way. The stated goal, from the original project doc, was to raise engagement: the previous two-thumbs survey had a low response rate.

**How it is used**

**1.** An agent closes a case, or simply replies to the customer in the ongoing thread.

**2.** The customer receives an email with the five-emoji row at the bottom.

**3.** They click one emoji. That single click writes the rating to the Case — nothing else is required of them.

**4.** A Unity-branded page opens headed "Thanks for letting us know!" asking three more things: how they rate the speed, whether the representative was helpful, and a free-text box.

**5.** If they fill those in and press Submit, three more fields are written and the case is flagged as a completed submission.

**6.** Support management reads the result on a Salesforce dashboard; the score is computed from the picklist answers (§9).

**The one thing a newcomer gets wrong:** there are two separate writes, not one. The emoji click writes the rating on page load. The Submit button writes everything else. A case can therefore sit with a rating and no speed, no helpfulness and no comment — that is normal, it means the customer clicked and walked away. Roughly half of all rated cases look like that.

# 2. Where it lives — the moving parts

| **Piece** | **Name** | **What it does** |
|---|---|---|
| **Live** | | |
| Record-triggered flow | Case - Send CSAT for closed cases (iAds,uAds,Tapjoy) | Active. After-save on Case update. The only thing that sends a CSAT email at case closure. Decides whether to send at all, then picks version A or B. Full rules in §5. |
| Email alerts | CSAT_Closed_Case_mobile_ACSAT_Closed_Case_mobile_B | Called by the flow. Both send from growth-support@unity3d.com to Customer_s_Email__c. |
| Closed-case templates | New_CSAT_Mobile_Closed_Case_1748335351328 (A)New_CSAT_Mobile_Closed_Case_B_1756895055156 (B) | Carry the five-emoji row tagged Version A and Version B respectively. Both in the unfiled$public folder. |
| In-thread templates | Mobile_Support_1638972653777SMB_Unity_1689090447776 | The default DSE reply templates, in the SMBDSETemplates folder. Carry the same emoji row tagged Email, so a customer can rate mid-conversation without waiting for closure. |
| The form | FormTitan project unity_csat | Hosted at ironsrc.formtitan.com. Edited at [formtitan.com/project/68b814f6c851fdffd4c3474d](https://formtitan.com/project/68b814f6c851fdffd4c3474d). Holds the three follow-up questions and both write-backs to Salesforce. |
| Community widget | customerPortalCaseDetail (LWC) + CustomerPortalCaseDetailController.updateCsatFeedback | The rating strip on the case detail page in the customer portal. Does not use FormTitan at all — see §6. |
| Case fields | Six of them | The whole result set. Listed in §4, with their misleading names called out in §8. |

# 3. The rating link, taken apart

Every emoji in every template is an image inside an anchor tag pointing at the same page, with three query parameters. This is the production URL, exactly as it appears in the closed-case A template:

*https://ironsrc.formtitan.com/ftproject/unity_csat?fld25=Version%20A&fld24=Very%20Good&fld23={{{Case.Id}}}*

Between the five emoji in one email, the only thing that differs is fld24. Between one template and another, the only thing that differs is fld25. Everything else — the host, the project slug, the Case Id merge field — is identical everywhere.

| **Parameter** | **Carries** | **Values and behaviour** |
|---|---|---|
| fld23 | The Case Id | A Salesforce merge field, {{{Case.Id}}}, resolved by the email template at send time. This is how the form knows which record to update. If it is empty or malformed the form has nothing to write to and the click is lost silently. |
| fld24 | The rating | Hardcoded per emoji: Very Good, Good, Neutral, Bad, Very Bad — in that order, left to right. The value is the label, not a number; the numeric score is derived later in reporting. |
| fld25 | Which surface it came from | Hardcoded per template: Version A, Version B or Email. The Community widget writes Community instead. This is what lets you tell a closed-case rating from a mid-thread one. |

**The two-stage write-back**

  - > **Stage one — on page load.** Opening the link is enough. A custom action attached to the form's GET reads the three parameters and updates the Case immediately, before the customer has done anything else. This is deliberate: most people click an emoji and never look at the page. That single call writes the rating and the source.

  - > **Stage two — on Submit.** If the customer answers the three follow-up questions and presses Submit, a second call writes the speed, the helpfulness answer, the free text and the submitted flag.

# 4. What lands on the Case

Six fields, all on Case, all standard-looking picklists and text. There is no CSAT object, no survey record, no junction. That is the good news. The bad news is in the naming — see §8.

| **Question / parameter** | **Case field** | **Field label** | **Written** | **Values** |
|---|---|---|---|---|
| **Stage one — written the moment the link opens** | | | | |
| fld24 — the emoji | Feedback_Type__c | Feedback Type | On page load | Very Good, Good, Neutral, Bad, Very Bad. The picklist also still holds Positive, Negative and Promote from the previous two-thumbs generation. |
| fld25 — the surface | Purchase_Type__c | CSAT Source | On page load | Version A, Version B, Email, Community. Software Market and Hardware Market are leftovers from the field's original purpose. |
| **Stage two — written only if the customer presses Submit** | | | | |
| "How would you rate the speed the support team resolved your issue?" | Speed__c | Speed | On Submit | Slow, Average, Fast. Also holds Excellent, Fair and Poor from the previous generation. |
| "Was your support representative helpful in resolving your problem?" | Quality__c | Quality | On Submit | Yes, No. Also holds Excellent, Fair and Poor from the previous generation. |
| "Additional Comments" | Customer_Suggestions__c | Customer Suggestions | On Submit | Free text, long text area up to 15,000 characters. Optional — frequently empty even on complete submissions. |
| — (no question) | Security_Q1__c | CSAT Submitted | On Submit | TRUE. This is the flag that separates "clicked an emoji" from "filled the form in". |
| **Timestamp** | | | | |
| — (no question) | Feedback_Date_Stamp__c | Feedback Date Stamp | With the rating | Date/time. Use this, not LastModifiedDate, when you need to know when feedback arrived. |

# 5. Who gets a CSAT email at closure, and who does not

One flow decides: Case - Send CSAT for closed cases (iAds,uAds,Tapjoy). It is an after-save record-triggered flow on Case update. Despite the name it covers Unity Support as well.

**Entry — all of these must be true**

| **Condition** | **Why it is there** |
|---|---|
| Status is Closed and Status changed | Fires once, on the transition into Closed — not on every later edit of a closed case. |
| Internal_Case__c = false | Internal tickets do not get surveyed. |
| Closed_Automaticlly__c = false | Cases the system closed on a timer never had a human interaction to rate. (The field name is misspelled in the org — spell it that way or your filter will not match.) |
| Customer_s_Email__c is not blank | There is nowhere to send it otherwise. |
| Do_not_notify_on_case_closure__c = false | The per-case opt-out. Agents set this when a customer has asked not to be emailed. |
| Feed_Type__c is blank | Excludes cases that came in through the feed rather than from a customer. |
| Record type is Unity_Support, Mobile_Support, Tapjoy_Support or Mobile_Demand_Support | Four record types, and only these four. Mobile Demand was added after launch — it was originally missing and got no CSAT at all. |

**Then two reasons to stop anyway**

  - > **The account is internal.** Name_for_email_alert__c contains the text "Internal Account".

  - > **The case is more than 14 days old.** A formula, DaysSinceCreation = DATETIMEVALUE(TODAY()) − DATETIMEVALUE(CreatedDate), and if it exceeds 14 the flow ends. The reasoning is that asking someone to rate an interaction they had a fortnight ago produces noise. In practice it means long-running cases — often the difficult ones — are systematically excluded from the score. Worth remembering before anyone reads the average as representative.

# 6. The three places a customer can rate

| **Surface** | **Tagged as** | **How it works** |
|---|---|---|
| Closed-case email | Email | Sent by the flow in §5 when the case closes. One email, one row of five emoji, links to FormTitan. |
| In-thread email | Email | The standard DSE reply templates carry the same emoji row, so the customer can rate at any point in the conversation without waiting for closure. Nothing schedules this — it rides along on whatever the agent sends. This is the largest single source of ratings by some distance. |
| Customer Community | Community | A rating strip on the case detail page in the portal. This one does not touch FormTitan: the component calls Apex directly and writes the Case in the same transaction. |

**The Community path is genuinely different**

Worth spelling out, because it looks like the same feature and is not. The component customerPortalCaseDetail renders five emoji buttons and, on click, calls CustomerPortalCaseDetailController.updateCsatFeedback with the Case Id and the chosen label. That method sets exactly two fields — Feedback_Type__c and Purchase_Type__c = 'Community' — and nothing else. There is no form, no follow-up questions, no speed, no helpfulness, no comment, and no Submit stage. A Community rating can never have a Speed__c value.

Before writing, the controller runs verifyUserPermission: the running user's email must match the case's Customer_s_Email__c or appear in Additional_Recipients__c, the case must not be internal, its record type must be one of Mobile_Support, Mobile_Demand_Support, Tapjoy_Support, Unity_Support, Fraud_Claim or Finance_Support, and Origin must not be onBoarding. Fail any of those and the customer sees "Failed to save feedback."

**Volume check:** the Community path has produced a handful of ratings against roughly 1,700 from email. If someone asks why the portal number is so small, that is why — it is new, and it is the only surface a customer has to go looking for.

# 7. Version A, Version B, and where that stands now

The two versions were a real experiment, and knowing how it ended will save you a confusing afternoon.

  - > **What they were.** Version A opened a form with the three structured questions plus a comment box. Version B opened a bare free-text box — the theory being that less friction would produce more responses.

  - > **What happened.** Version A came out ahead on submission rate, 86.7% against 50%, on an early sample of 105 responses and an overall response rate of about 5%. The conclusion drawn was that a guided, structured survey works better for Unity's customers than an open box.

  - > **What was decided.** The business chose to keep the structured form and stop sending the free-text one. The per-version tiles were removed from the dashboard because they were no longer meaningful.

# 8. Field names that will mislead you

Almost every field in this process is a repurposed one. The API name describes what the field used to be; the label describes what it is now. Reports show the label, the metadata and any code show the API name, and the two do not agree.

| **API name** | **Label you see in reports** | **What it actually holds** |
|---|---|---|
| Purchase_Type__c | CSAT Source | Which surface the rating came from. Nothing to do with purchases. Still carries Software Market and Hardware Market as dead values. |
| Security_Q1__c | CSAT Submitted | Whether the customer pressed Submit. Nothing to do with security. Security_Q2__c through Q4__c next to it are unrelated checkboxes and are not part of CSAT. |
| Quality__c | Quality | Now a Yes/No answer to "was your representative helpful". Historically held Excellent / Fair / Poor. Both generations of values are live in the picklist and in the data. |
| Speed__c | Speed | Now Slow / Average / Fast. Historically Excellent / Fair / Poor. Same double-generation problem. |
| Customer_Suggestions__c | Customer Suggestions | The "Additional Comments" free text. The form wording and the field label are different words for the same box — searching the org for "comments" will not find it. |
| Random_0_1__c | Random (0 / 1) | Not random. MOD(VALUE(CaseNumber), 2). |
| Closed_Automaticlly__c | Closed Automatically | Spelled without the second "a" in the API name. Copy it, do not type it. |

**Practical consequence:** when you build a report filter, pick the field from the picker rather than trusting a name you remember. Two of these — Feedback_Type__c and Quality__c — will happily accept a value from the wrong generation and give you a silently empty result.

# 9. Reporting

**The dashboard**

The support CSAT dashboard is the one management reads. It shows the total number of CSATs sent, then splits the total by source — closed-case form A, closed-case form B, and ratings filled in mid-conversation rather than at closure — plus two computed averages.

| **Element** | **How it is built** |
|---|---|
| Helpfulness average | Quality__c scored No = 0, Yes = 100, summed and divided by the number of responses. |
| Speed average | Speed__c scored Slow = 0, Average = 50, Fast = 100, summed and divided by the number of responses. |
| Default scope | Cases created in the last 90 days, filtered to ratings from the new process onward so that legacy two-thumbs data does not contaminate the averages. |
| Open / Closed filters | Top-of-dashboard filters, because a rating can arrive mid-thread on a case that is still open. |
| Known gap | There is no funnel component — cases closed, versus emoji clicked, versus form submitted. It was identified as missing and never added. Until it exists, "response rate" has to be worked out by hand. |

# 10. Troubleshooting

**"The customer says they rated it and nothing shows"**

**1.** Check which surface. Open the Case and read CSAT Source. Blank means no rating of any kind arrived — carry on down this list. A value means something did land and the question is which field is missing.

**2.** Separate the two stages. Feedback Type populated but Speed, Quality and CSAT Submitted empty is not a bug: the customer clicked the emoji and closed the tab. Only chase it if CSAT Submitted is TRUE and the other fields are still empty.

**3.** Check the case ever qualified. Run through the §5 entry conditions on the record — record type, Internal Case, Closed Automatically, Customer's Email, the notify opt-out, Feed Type. One false and no email was ever sent.

**4.** Check the 14-day rule. If the case was created more than a fortnight before it closed, the flow stopped deliberately. This is the most common answer and it is not a fault.

**5.** Check the email actually went. Look at the Activity timeline for the alert from growth-support@unity3d.com. If it is absent the flow did not fire; if it is present the link was delivered and the problem is downstream.

**6.** Check the link itself. Open the sent email and inspect one emoji's href. fld23 must contain a real 18-character Case Id. If it resolved to blank, the template merge failed and every emoji in that email is dead.

**7.** Only then look at FormTitan. If the URL is correct and the click still wrote nothing, the custom action on the form's GET is the suspect (§3).

**Known failures and what they mean**

| **Symptom** | **Cause and fix** |
|---|---|
| Community: "Failed to save feedback." and INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST on Purchase_Type__c | The Apex controller writes the literal string Community into Purchase_Type__c, which is a restricted picklist. If that value is missing from the picklist — which is exactly what happens in a fresh sandbox or after a partial deployment — every portal rating fails. Add the value. This has bitten twice. |
| Community: the rating takes several seconds and the customer is not sure it worked | The Apex call is synchronous with no spinner. The green toast is the only confirmation, and full errors go to the browser console rather than the screen. Known, unfixed, worth a spinner. |
| The emoji render as broken images | The five emoji are Salesforce static resources served by document Id. They will not resolve in a sandbox unless the images were deployed too. A sandbox showing broken CSAT images is expected, not a bug. |
| A rating exists on a case that was never closed | Expected. The in-thread emoji row rides on ordinary replies, so any open case in an active conversation can pick up a rating. |
| The same customer rates twice | Possible by design — the links do not expire and nothing prevents a second click. The agreed rule is to count the most recent response per case, not the first. |

