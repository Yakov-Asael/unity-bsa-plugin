# Knowledge

> Source: BSA Process Handbook, tab "Knowledge". Verbatim.

**Knowledge**

**Process:** Salesforce Knowledge — the team says "KB article", "FAQ" or just "article" · **Object:** Knowledge__kav, record types External and Internal only · **Date:** 10 August 2026 · **Business owner:** Shani Kovalsky, with Michal Smithline (CSS external), Matthew Hunter (CSS internal) and Andrii Bosak (DSE) · **Technical owner:** Dror Diamant → Neta Ronen

*§1–3 how the process works · §4–9 how it is built · §10 troubleshooting · §11–12 where to look next.*

# 1. What this process does

Knowledge is Unity's support article base. External articles are customer-facing: they feed the Grow Ads support portal, the Fin AI assistant that answers customers directly, and search on the documentation site. Internal articles are staff-only. Two teams write them — CSS, the non-technical customer support team, and DSE, the technical support engineers. The process exists so that an article is written to a template, checked by a named reviewer before it goes live, and then re-checked every three months so the base does not quietly rot. Around 110 to 120 External articles are published at any time, which makes this a small, quality-driven process rather than a high-volume one.

**Lifecycle**

**1.** An author creates the article from the Create new article button — usually on a Case, sometimes from the Knowledge tab. They choose Internal or External and a Type, and the flow opens a pre-filled template.

**2.** The article is saved as a Draft and a reviewer is resolved automatically from the author's role crossed with the record type (§7). The author cannot pick the reviewer.

**3.** The reviewer checks the content, sets the visibility flags — Visible to Customer and Visible in Public Knowledge Base — and publishes.

**4.** A day after publication the article is picked up and a Knowledge Article Review record is created, with an expected review date of the publish date plus three months.

**5.** On that date the reviewer is emailed and a Reviewed button appears on the review record. The email asks for the review to be completed within two weeks.

**6.** The reviewer either republishes the article, or clicks Reviewed to confirm nothing needed changing. Either way the current review closes and a new one opens three months out, so the cycle never ends.

# 2. Where articles are created, and how they reach publication

| **Entry point** | **How it works and what to know** |
|---|---|
| Case → Create new article | The intended path. The quick action launches Knowledge_Create_a_new_template, which asks for Demand or Supply, the Product, Internal or External, and the Type, then creates the article with a template already in the body. The button does not appear on every Case — it is exposed only for products with knowledge-base coverage, which users regularly report as a bug. |
| Knowledge tab → Create new article | The same flow, but with a consequence nobody expects: an article created this way sends no notification to the reviewer. A batch of roughly 45 drafts once sat unnoticed for four months because of it. If a reviewer says they never heard about an article, check where it was created from. |
| Ask-AI / Mosaic — "Send to External KB" | The AI drafting tool can push an article straight into Salesforce. Note that "Published" inside Ask-AI affects only Ask-AI; "Send to External KB" is the button that actually creates the Salesforce article. You can recognise these: their URL name is a user ID plus a timestamp rather than a readable slug. |

**How an article reaches the customer**

  - > Only the reviewer publishes. The author saves a draft; publication is the reviewer's action and it is what counts as approval.

  - > The visibility flags cannot be set at creation. They appear on the draft review step, so the reviewer sets them — which is why so many older articles were published without Visible in Public Knowledge Base and never reached the portal.

  - > The portal shows an article only when the record type is External, the status is Published, it is the latest version, and Category is not blank. An article missing a Category is invisible to customers however well written it is.

  - > On the portal, Department maps to the customer's language: Supply is shown as Monetization, Demand as User Acquisition.

  - > Unpublishing does not require archiving. Clearing Visible in Public Knowledge Base takes an article off the portal while leaving it published internally.

# 3. The Customer Community — visibility, ratings and promoted articles

Everything in this section is Apex, not configuration. The community is a set of Lightning web components backed by CustomerPortalController, CustomerPortalArticleController and CustomerPortalCategoryController, so none of it can be changed in Setup and none of it shows up when you audit flows. Read the classes before you promise anybody a change.

**When an article appears in the community**

The portal applies three conditions, and every query in the code repeats them. Record type is not one of them.

| **Condition** | **Field tested** | **What it means in practice** |
|---|---|---|
| It is published | PublishStatus = 'Online' | Draft and archived versions never appear. Only the live version is queried. |
| It is customer-visible | IsVisibleInCsp = TRUE | This is the "Visible to Customer" checkbox the reviewer ticks at publish. It is by far the most common reason a published article does not show — an article can be perfect, live and completely invisible because this was missed. |
| Visible in Public Knowledge Base | IsVisibleInPkb = TRUE | Guest users — anyone who reaches the site without logging in. This is the "public" flag. Without it an article can only be read by a customer who has signed in. |
| It is categorised | Category__c != null | Applied to every list, every category page and search. An uncategorised article cannot be found by browsing. |

**How article ratings work**

Ratings live on their own object, Knowledge_Rating__c — one record per person per article. It is a deliberately small object and the whole helpful-count feature rests on five fields.

| **Field** | **Type** | **What it holds** |
|---|---|---|
| Like__c | Checkbox | The positive vote. Counting these is the entire "N found this helpful" figure. |
| Dislike__c | Checkbox | The negative vote. |
| Dislike_Reason__c | Long text | Free text captured when someone votes negatively. The only qualitative feedback the process collects anywhere. |
| Knowledge_Article_Id__c | Text | The master article Id — not the version. This is the field every count is grouped by. |
| Knowledge_Version__c | Lookup to Knowledge__kav | The specific version that was rated, kept for traceability only. Nothing counts on it. |

**The behaviour that follows from that design**

  - > Ratings survive republishing. Because counts group on the master article Id rather than the version, editing and republishing an article does not reset its helpful count. That is intentional and it is the reason two Id fields exist.

  - > One vote per person per article, and it can be changed. On submit, the controller looks for an existing rating created by that user for that article; if it finds one it updates it, otherwise it creates one. Nobody can stack votes.

  - > The helpful count shown to customers is a live COUNT of ratings where Like__c is true for that master article. There is no roll-up field and no stored total.

  - > KnowledgeRatingAction is an invocable Apex action that returns the like and dislike counts for an article. It is what the internal rating screen calls, and it is available to any flow that needs the numbers.

**How an article gets promoted on the community home page**

**To promote an article**

**1.** Confirm the article is Published and Visible to Customer. If it is not, nothing below will have any effect.

**2.** Create a Promoted_Articles__c record.

**3.** Set Knowledge__c to the article. Note this is a lookup to Knowledge__kav, which means a specific version — see the warning below.

**4.** Set Order__c to the position you want. Lower numbers appear first; records with no order sort last.

**5.** Tick Active__c. The change is live on the next page load; there is no cache to clear and no flow to run.

**6.** To unpin, untick Active__c rather than deleting the record — it keeps the history and the ordering intact for next time.

**The trap: a pin breaks when the article is republished.** Promoted_Articles__c.Knowledge__c points at a specific article version, and the query matches on that version Id. Publishing a new version creates a new Id, so the pin stops matching and the article silently drops off the home page. Anyone who republishes a pinned article has to re-point the pin afterwards. Nothing warns you.

# 4. The flows — what each does and what triggers it

Seven active flows and one inactive. Everything that matters runs on a daily schedule rather than in real time, so nothing in this process happens instantly — expect roughly a day between an action and its consequence.

| **Flow** | **Trigger** | **What it does** |
|---|---|---|
| **CREATION** | | |
| Knowledge_Create_a_new_template | Screen — Create new article, from a Case or the Knowledge tab | When an author picks a record type and a Type, it resolves the record type ID, builds a title from the naming pattern for that combination, writes the matching template into Answer__c and creates the article. The URL name is generated as the author's user ID plus a Unix timestamp, which is why article URLs are unreadable. The two record type IDs are hardcoded in a formula rather than looked up. |
| Knowledge_After_Creation_Trigger ° | Knowledge, after save | The newest flow in the set and the presumed replacement for the inactive review-creation flow below. Not present in the metadata repo, so read it in Flow Builder before assuming what it does — it is the most likely place the reviewer stamping and the first review record now happen. |
| **THE REVIEW CYCLE** | | |
| Knowledge_Create_knowledge_review_3_months_from_last_publish_date — INACTIVE | Scheduled daily, on articles where Need_Review__c is true | This was the engine. It found articles published the previous day, looked for an existing open review on the same parent article, closed it as Completed with New Version Published ticked when a newer version had appeared, otherwise updated its expected date — and where no review existed, created one dated three months after the last publish, with the reviewer resolved from the metadata table. It logs failures to ErrorObject__c. |
| Knowledge_Article_Review_an_article_button | Screen — the Reviewed button on a review record | When the reviewer confirms, it marks the current review Completed, ticks Knowledge Reviewed, stamps who and when, clears the expected date — and immediately creates the next review record dated three months from today. This is what makes the cycle perpetual, and it is also the only path that records a review when the article did not need changing. |
| **NOTIFICATIONS** | | |
| Knowledge_Quarterly_review_notification | Scheduled daily, on review records where Send_Notification__c is true — that is, where the expected review date is today and the article is not archived | Resolves the reviewer from the same metadata table and emails them "New knowledge for your review - `[title]`". Fires once, on the day, and never again — there is no chaser, which is worth knowing given how large the overdue queue is. Logs failures to ErrorObject__c. |
| Knowledge_Send_Last_Week_Published_Knowledges ° · PE_Weekly_Published_Knowledge_Notification ° | Scheduled weekly, then a platform event | Together they post the weekly digest of newly published articles to Slack. The digest keys on publish date, not creation date, so a bulk re-publish makes old articles look new — that has been reported as a bug more than once and is working as designed. |
| **SUPPORTING** | | |
| Knowledge_Rating_Screen ° | Screen | The internal rating capture behind the like and dislike counts shown on the article record page. It reads its numbers from the KnowledgeRatingAction Apex action (§3). |

*° Live in the org but absent from the metadata repo snapshot — description taken from the flow label, the org metadata and design documents; confirm in Flow Builder.*

# 5. What blocks users, and why

*There is not a single validation rule on Knowledge__kav. Everything that stops a user is either a platform behaviour, a permission, or a formula field controlling whether a button appears. That is unusual enough to be worth stating plainly, because a new owner looking in Setup for the rules will find nothing.*

| **What stops the user** | **Where it lives** | **What it means in practice** |
|---|---|---|
| A published article cannot be edited | Salesforce platform behaviour | Not a rule anyone wrote. Use Edit as Draft, which creates a new version; publishing it archives the previous one. This constraint is the reason the whole review cycle lives on a separate object. |
| The Reviewed button is not visible | Show_Review_Button__c — a formula: expected review date is today or earlier AND review status is Open | The most common "it is broken" report. The button genuinely does not exist before the review date. There is no way to review early. |
| No review email arrived | Send_Notification__c — a formula: expected review date equals today AND the article is not Archived | It fires on exactly one day. Miss it and nothing chases you, which is a large part of why 171 reviews are overdue. |
| No review record was created | Need_Review__c — a formula: exactly one day after the last publish date, publish status Online, and record type Internal or External | Note the equality. It is true on day one and never again, so if the nightly job does not run that day, that article never gets a review record at all. |
| The visibility flags are missing at creation | Page layout — the flags live on the draft review step | By design. The author cannot set them; the reviewer does, at publish. Articles published without them never reach the portal (§3). |
| Create new article is missing on a Case | Quick action exposure by product | Intended — the button appears only for products with knowledge coverage. Users read it as a bug; check the product before checking permissions. |
| Cannot edit, publish or delete | Permission sets, granted individually | Access has been handed out person by person since launch. Deleting drafts is admin-gated on purpose. There is no self-service route — requests go to the Salesforce team. |

# 6. Approval processes

None. There is no approval process on Knowledge__kav, no approval steps and no approval history. Publishing is the approval: the reviewer reads the draft, sets the flags and hits Publish, and that act is the control. Be aware of one live contradiction — the programme tracker records a decision that "no approval needed for external articles", while the reviewer assignment, the new-article alert and the whole review cycle all assume a reviewer gates publication. Settle that with Shani Kovalsky before changing anything, because the two readings imply very different controls.

# 7. Who reviews each article

The reviewer is not chosen by the author and is not stored as a rule anywhere in the flows. It is resolved from a custom metadata table, Support_Knowledge_Reviewers__mdt, on two keys: the author's role and the article's record type. The role is derived by a formula that checks whether the author's Salesforce role name contains "DSE" — if it does the author is treated as DSE, and if it does not they are treated as CSS. That is worth pausing on: anyone whose role name does not mention DSE is CSS by default, including people in neither team. Every flow in the cycle resolves the reviewer the same way, so changing a reviewer is a metadata change and takes effect immediately for future assignments.

| **Author's role** | **Record type** | **Reviewer stamped on the article** | **Who is emailed** |
|---|---|---|---|
| CSS | External | User 005b0000003npfuAAA | shani.kovalsky@unity3d.com, michal.smithline@unity3d.com |
| CSS | Internal | User 005Qv00000DQpvVIAT | matthew.hunter@unity3d.com, iryna.paulouskaya@unity3d.com |
| DSE | External | Andrii Bosak | andrii.bosak@unity3d.com |
| DSE | Internal | Andrii Bosak | andrii.bosak@unity3d.com |
| Default — used when no row matches | any | Andrii Bosak | andrii.bosak@unity3d.com |

**Four things about this table that will save you a bad afternoon**

  - > The Reviewer field on the article can look wrong and still be right. Only one user can be stamped, but two people are emailed. For CSS articles the stamped user and the notified people are deliberately not the same, so do not "fix" the field because it does not match who replied.

  - > The Recipients and Reviewer Name columns are inconsistent between the CSS and DSE rows in the metadata. Check which field each flow actually reads before editing a row — this is the likeliest cause of a notification going to the wrong person.

  - > The Default row exists for one reason: the person who last edited an article may have left the company. Without it the cycle would stall on every departed author.

  - > The reviewer is stamped at creation and not re-resolved. Change the metadata and existing articles keep the old reviewer — the same failure mode as every other stamped-approver process in this org.

**If the wrong reviewer was assigned:** the supported workaround is to open the article with Edit as Draft and change the Reviewer field by hand. That is what the team does today.

# 8. Other mappings in the process

This process is driven almost entirely by formula fields rather than by automation logic. Change one of these and you change the behaviour of every flow at once, without touching a flow.

| **Field** | **What it evaluates** | **Why it matters** |
|---|---|---|
| Need_Review__c (on the article) | Exactly one day after the last publish date, publish status Online, record type Internal or External | The entry filter for review creation. Because it tests equality rather than a range, an article is eligible on one day only. |
| X3_Month_from_Publish_Date__c (on the article) | Last publish date plus three months | The source of the review deadline. Republishing moves it, which is how the countdown resets. |
| Send_Notification__c (on the review) | Expected review date equals today AND the article is not Archived | The entry filter for the reminder email. Fires once, with no follow-up. |
| Show_Review_Button__c (on the review) | Expected review date is today or earlier AND review status is Open | Controls whether the reviewer can act at all. |
| Knowledge_Status__c (on the review) | The article's publish status, pulled through the lookup | How the review record knows whether its article has been archived underneath it. |
| Creator_Role__c (on the article) | CSS or DSE, from whether the author's role name contains "DSE" | The first key into the reviewer table (§7). |
| Support_Knowledge_Reviewers__mdt | Role plus record type, with a Default fallback row | The reviewer table itself. Five rows, and the only place reviewer routing is configured. |
| Portal_Product__mdt | Product plus department filter, with an order and an active flag | Decides which products get a page in the community and what appears on it (§3). |
| Record type IDs in the create flow | Internal 012Qv00000393pmIAA, External 012Qv00000393plIAA | Hardcoded in a formula rather than looked up. Same IDs appear in the portal design document, so a record type change would break both. |

# 9. Notifications

| **Notification** | **Trigger** | **Recipients** | **Channel** |
|---|---|---|---|
| A new article needs your review | Article created from a Case | The reviewer resolved from §7 | Email — carries team, product and whether it is Internal or External |
| Time to review this article | The expected review date arrives and the article is not archived | The reviewer resolved from §7 — both addresses where the row has two | Email — "New knowledge for your review - `[title]`". Asks for completion within two weeks |
| Weekly published digest | Scheduled weekly, via a platform event | The team Slack channel | Slack — lists articles published that week with their author. Keys on publish date, so a bulk re-publish makes old articles reappear |

**There is no escalation and no chaser.** The review reminder fires on a single day. If the reviewer misses it, nothing else happens — no second email, no manager notification, no report. That is the mechanical reason the overdue queue has grown to 171 and why the oldest item has sat almost a year.

# 10. FAQ

**Check these five first:** (1) Is the article on the Internal or External record type, or one of the eight legacy ones the flows ignore? (2) Is it Published, and is it the latest version? (3) Is Category populated — without it the portal will not show it? (4) Was it created from a Case or from the Knowledge tab? (5) Has the expected review date actually arrived?

| **Symptom, in the user's words** | **Cause and fix** |
|---|---|
| "I can't tick Visible In Public Knowledge Base when creating the article. Is this a bug?" | No, by design. Those flags appear on the draft review step, not at creation. The flow is: the article is created, the reviewer checks the content, sets the flags and publishes. |
| "The article is published but customers still can't find it." | Work through the three portal conditions in order (§3): is it Online, is Visible to Customer ticked, and is Category populated. The second is the usual culprit. If the customer has a direct link and it opens, but nobody can find it by browsing, it is the Category. |
| "We sent a customer the article link and they were asked to log in before they could read it." | The article is Visible to Customer but not Visible in Public Knowledge Base. The first flag admits signed-in community users; the public flag is what admits guests (§3). Open it with Edit as Draft, tick Visible in Public Knowledge Base, and publish again. |
| "I pinned this article as promoted and it disappeared from the home page after we updated it." | Expected, and it catches everyone. The pin points at a specific article version; republishing creates a new version Id and the pin no longer matches (§3). Re-point the Promoted_Articles__c record at the new version. |
| "Can we control which articles show on the community home page?" | Only the first twelve slots, and only through Promoted_Articles__c. Anything you do not pin is filled automatically by the most-liked articles and then by whatever else qualifies (§3). There is no way to blocklist an article from the filler pass short of unpublishing it. |
| "We republished the article — does that wipe the helpful votes?" | No. Ratings are counted against the master article Id rather than the version, so the count carries across versions (§3). |
| "I can't choose the reviewer any more. Who gets it?" | Reviewer assignment is automatic now, from your role crossed with the record type (§7). If it picked the wrong person — which happens when a non-technical author has a role that reads as DSE, or the reverse — open the article with Edit as Draft and change the Reviewer field by hand. |
| "I'm not getting any notifications as a reviewer. Should I set something up?" | Check three things in order: whether the article was created from a Case or from the Knowledge tab, because the tab path sends nothing; whether your address is on the right row of the reviewer table (§7); and whether the expected review date has actually arrived, since the reminder fires on that one day only. |
| "I need to add the Category field to articles that are already published — do I have to recreate them?" | No. Click Edit as Draft, add the Category, confirm the article still matches the current template, tick Visible in Public Knowledge Base, and publish again. Bear in mind this counts as a new publish, so it resets the three-month clock and puts the article in the weekly digest. |
| "We're getting Slack alerts about old articles — these weren't created this week." | Working as designed. The digest reports what was published, not what was created. Any bulk re-publish, such as a Category backfill, makes older articles reappear in it. |
| "I reviewed the article and republished it. Do I need to do anything else?" | No — wait about a day. The nightly job closes the existing review, marks it as superseded by a new version, and creates the next one three months out. If you republished before the review date, the old review is completed rather than left open. |
| "The article didn't need any changes. How do I record that I reviewed it?" | Use the Reviewed button on the review record. That is exactly what it is for — it stamps who reviewed it and when, closes the review, and starts the next three-month countdown without touching the article. |
| "Most of my Cases don't show the Create New article button." | Expected. The button is exposed only for products with knowledge-base coverage. Check the product on the Case before raising a permissions request. |
| "The team can't edit the articles they created, and they can't see articles created by others." | A permissions problem, and a recurring one. Editing, publishing and deleting drafts are separate grants handed out individually. Raise it with the Salesforce team rather than trying to fix it on the record. |
| "Which field holds the article body?" | Answer__c, not Body__c. Anything reading articles programmatically — the portal, the AI assistant, an export — must read Answer__c. |
| "Some article URLs are readable and some are a long string of characters." | Both are normal. A readable slug means a human created the article; a user ID plus a timestamp means it came from the AI drafting tool. It is customer-visible in AI citations and there is no fix in place. |
| "Do external articles need sign-off from the documentation team?" | No. The ruling is that every article needs a review by an authorised reviewer within the team, and it is the reviewer's own judgement whether a particular article should also go past legal, marketing, docs or product. |
| "Should we be creating internal articles at all?" | Only non-technical ones. Technical internal documentation lives in Confluence; non-technical internal documentation lives here; everything external lives here. That split is the reason the Internal record type looks under-used. |

*Escalation: editorial questions, publishing authority and anything needing a business decision go to Shani Kovalsky. Day to day, external CSS articles go to Michal Smithline, internal CSS articles to Matthew Hunter, and anything DSE to Andrii Bosak. Salesforce configuration, permissions and flow faults go to Yakov Asael. The build history and every past bug are in the private #external_knowledge_salesforce_project channel; permission requests are raised in #salesforce-issues-tams; portal rendering issues in #proj-ads-support-portal.*

# 11. Dashboards and reports

**There is no report on the review cycle.** Not one report in the org covers Knowledge Article Review records — no overdue list, no completion rate, no per-reviewer load. The team works from three list views instead. Given that 171 reviews are overdue and nothing chases them, an overdue-review report with a scheduled subscription is the single cheapest improvement available to whoever takes this over.

| **Report** | **Folder** | **What it is for** |
|---|---|---|
| **WHAT THE TEAM ACTUALLY USES** | | |
| [Support Articles](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000DL2fFMAT/view) | (Shared) CSS Team | The only knowledge report run recently and the closest thing to a working inventory. Start here. |
| [CSS Knowledge Articles](https://ironsrc.lightning.force.com/lightning/r/Report/00OQv00000DLxs1MAD/view) | (Shared) CSS Team | The CSS team's own article list. A near-identical "Copy of" exists — check which one a colleague means. |

*There are no dashboards. The three Knowledge Article Review list views shipped with the review process — All, CSS and DSE — are the working tool, alongside the CS and DSE article boards on the Knowledge tab. Note also that nothing reports on ratings: the like and dislike counts are calculated live by Apex and stored nowhere, so there is no way to report on the least helpful articles without building it.*

# 12. Related documents

| **Document** | **Type** | **Open this when…** | **Status** |
|---|---|---|---|
| **REQUIREMENTS & DESIGN** | | | |
| [Knowledge Articles Process in Salesforce](https://docs.google.com/presentation/d/18jiK0geiDpkrG0JMB_1F77WT4mHRVsQA517eLP_D8qI/edit) | Slides | You want the whole process in one narrative — creation, permissions, versioning and the review rules, including what happens when a republish beats the review date. | Current, but written before the team was renamed from SMB to CSS |
| [PRD - Customer Community V2](https://docs.google.com/document/d/1Qb0ntdtvc-SY0D6v3ZulJ-ftL-ZZyAaALnpdP4N5h70/edit) | Doc | An article is published but not appearing for customers. Carries the intended portal filter and the Department-to-audience mapping — compare it against what the Apex actually does (§3). | Draft — never signed off, although the build shipped |
| **BUILD & IMPLEMENTATION** | | | |
| [Knowledge reviewer fix](https://docs.google.com/spreadsheets/d/1XX8i2E_gpqvDaQpgEN5Fj-p9L6rldN3rRwNPYt3aDBk/edit) | Sheet | You need the reviewer matrix rows and the list of components to touch. The most recent artefact in the set and the only implementation record for the review build. | Current |
| [Knowledge Base - DSE Feedback Tracker](https://docs.google.com/spreadsheets/d/1nbMbgFMp1pcAC-50hnTgO2acYUkEriWUBT63wuPJx10/edit) | Sheet | You are wondering why Validation Status is unused — this is where that was decided. | Obsolete — four rows from the original DSE rollout |
| **TEMPLATES — what authors actually write from** | | | |
| [Templates (folder)](https://drive.google.com/drive/folders/1TysZASOIiybOXAqWzvEUmGGpuU2LwHR6) | Folder | An author needs the skeleton. Six live templates: External FAQ, How To and Issue Solution; Internal FAQ, How To and Process Guide. Note there is no External Process Guide. A "Not in use" subfolder holds superseded copies with identical titles. | Current — but confirm you are at the folder root, not in the retired subfolder |
| **POLICY & PROGRAMME** | | | |
| [GTM for FIN AI and Portal](https://docs.google.com/spreadsheets/d/1Jr5NrWfbkoU733D4DSbFLcyF1mB4Uw_zeY9nxpTASM8/edit) | Sheet | You need the formatting constraints the AI assistant imposes, the publishing-authority decisions, or the open article-gap backlog with owners. | Current — the live programme tracker |
| [Quarter SF article review email template](https://docs.google.com/document/d/17Gu8Sw1ff_t6HWgv3H2TDbFOGBp1QyGQU2qHOukcTog/edit) | Doc | You are changing the review reminder, or you need to tell a reviewer what they are actually being asked to do. Carries the two-week completion request. | Current |
| [A new article created template SF KB](https://docs.google.com/document/d/1p962tvzTafG0Hm_BB-BkjhUjeRvnmXZ1XtShAlRijh8/edit) | Doc | You are changing the new-article alert. Carries the wording that publication is gated on reviewer approval. | Current |

*Two gaps are worth naming. There is no writing or style guide anywhere — the only guidance that exists is a line inside the templates telling authors to avoid jargon, and the task to write publishing guidelines is still open on the programme tracker. And there is no PRD for the Knowledge build itself: the portal has one, the reviewer fix has an implementation sheet, but the record types, the review object, the review flows, the rating object and the promoted-articles logic were never specified in writing. For those, this guide and the Apex are the documentation.*
