# Customer Community

> Source: BSA Process Handbook, tab "Customer Community". Verbatim.

**Grow External Community**

**Process:** the customer-facing support portal at support-ads.unity.com · **Built on:** an Experience Cloud site, 18 custom Lightning web components, 7 Apex controllers, 7 custom metadata types, an Auth Provider into Unity ID and one scheduled batch · **Business owner:** Shani Kovalsky, Andrii Bosak and Aylin Lee (Grow Support) · **Technical owner:** Dror Diamant → Neta Ronen · **Developer:** Danill Rekov

*§1–3 what it is and how it is laid out · §4–6 users, access and ticket creation · §7–9 Knowledge, configuration and the public/private split · §10 troubleshooting · §11–12 watch-outs and who to ask.*

**Read this first.** Almost nothing on this site uses standard Experience Cloud behaviour. There is one Lightning web component that renders every page by reading the URL, and all seven Apex controllers are declared without sharing — so record-level security is not enforced by Salesforce anywhere in the portal. It is enforced by a WHERE clause on the customer's email address, repeated by hand in each controller. The retrospective deck says why: "the existing account and contact structure made it difficult to implement standard Salesforce best practices, forcing us to build a fully customized site from scratch." Read §5 before you change any controller.

# 1. What this site is

Grow External Community is the support portal Unity's Grow customers use to read help articles, open a support ticket and follow the tickets they already have. It is the customer-facing face of the Case object: everything a customer does here becomes a Case, a Case Comment, a file or a Knowledge rating in the same org the support agents work in.

It covers Grow products only — Ads Monetization, User Acquisition and Grow Finance. Unity Editor and game-development questions go to Unity Create support, and the portal is deliberately explicit about that split.

It was built in two phases. Phase one delivered cases: a home page, a submit-a-request form, a My Requests list and a request detail page. Phase two added Salesforce Knowledge, replacing Zendesk as the article source, plus search and the FIN chatbot.

**How it is used**

**1.** A customer arrives from the Unity dashboard, from a support email, or directly.

**2.** The main entry point authenticates them against Unity ID through Genesis. On a first visit this silently creates a Salesforce community User and, usually, a Contact.

**3.** They land on the Knowledge home page: navigation by product, promoted articles, an ecosystem link strip and a search box.

**4.** They read articles, and can mark one helpful or not helpful.

**5.** If that does not solve it they open Submit a Request, which resolves them to an Account and Contact behind the scenes and creates a Case with the right record type.

**6.** They track it in My Requests, add comments, attach files, close it themselves, and rate the service when it is done.

# 2. The moving parts

| **Piece** | **Name** | **What it does** |
|---|---|---|
| **The site** | | |
| Experience Cloud site | Grow External Community | Status Live. URL path prefix GrowClientsCommunity, mapped to the custom domain support-ads.unity.com. Internal user login is switched off. The production site is built on the Aura template; the sandbox copy was built on LWR, which is one reason some defects only appear in production. |
| Custom label | Customer_Portal_Navigation_URL_Path | Value is a single forward slash. Every URL the components build is prefixed with it. It exists because Salesforce Files and attachment links break unless the full custom-URL middle path is used — during testing it was set to /portal and switched to / at go-live. If the site ever moves to a sub-path, this label is the one thing you change. |
| **Back end — 7 Apex controllers, every one declared without sharing** | | |
| Home and search | CustomerPortalController | Navigation tree, ecosystem links, promoted articles, article search. |
| Product pages | CustomerPortalCategoryController | The per-product article listing and its filters. |
| Article page | CustomerPortalArticleController | One article, its related articles, and the helpful / not-helpful rating. |
| My Requests | CustomerPortalCasesController | The case list, its filters and its counts. |
| Request detail | CustomerPortalCaseDetailController | One case, its comments, its files, closing it, and the CSAT rating. |
| Submit a request | HelpCenterContactUsController and CustomerPortalContactUsController | Two of them, roughly 900 lines each, one a clone of the other — see §6. |
| Search helper | CustomerPortalUnitySearchHandler | Support class for search; not directly callable from the front end. |
| **Identity and access** | | |
| Registration handler | GrowthExternalRegistrationHandler | Implements Auth.RegistrationHandler. Creates the community User and, where needed, the Contact, on first login. §4. |
| Platform event | New_Community_User__e | Two fields: Customer_Email__c and ContactID__c. Published when a community user is created. |
| Subscriber flow | Case - Update Sharing Contact - PE | Active. Stamps Case.Sharing_Contact__c so the sharing set can grant access. §5. |
| Sharing set | Cases | Read on Case where Case.Sharing_Contact__c matches the user's Contact, for the two Login User profiles. Let the user see all related attachments. |
| Profiles | Customer Grow Community Login User (Customer Community Login licence)Grow External Community Profile (Guest User licence) | The logged-in customer and the anonymous visitor respectively. |
| Scheduled batch | MatchContactBatch | Runs daily. Merges placeholder contacts from Unity Users umbrella account into real ones and repoints their cases. §5. |

# 3. The pages, and how routing actually works

There is no page-per-component structure to navigate. customerPortal reads the browser path in connectedCallback, normalises it, and exposes a set of getters — isHome, isContact, isTickets, isTicketDetail, isSearchResult, isCategory, isArticle — that its template switches on. To find the code behind a page, match the URL to the getter, then to the child component.

| **Route** | **Getter** | **Component** | **What it shows** |
|---|---|---|---|
| /s or /s/knowledge | isHome | customerPortalHomeBanner + customerPortalHomePage | The landing page: hero banner, product navigation built from custom metadata, promoted articles, the Unity ecosystem link strip and search. |
| /s/category?name=…&sub=… | isCategory | customerPortalCategory | One product's articles, grouped by category. The name parameter is the product page API name; sub narrows to a category. |
| /s/article?name=… | isArticle | customerPortalArticle | One article by its UrlName, with breadcrumbs, related articles and the helpful / not-helpful buttons. |
| /s/article-search?q=… | isSearchResult | customerPortalSearchResults | Full search results with product and category facets. |
| /s/ContactUs | isContact | hcContent | Submit a Request. This is also the public, unauthenticated entry point. |
| /s/cases | isTickets | customerPortalCases | My Requests — the case list with status, product, date and opened-by filters. |
| /s/case | isTicketDetail | customerPortalCaseDetail | One request: detail, comment thread, attachments, close-case action and the CSAT strip. |
| /s/auth | — | standard | The Genesis login handoff. |

**Why the URL carries parameters**

When a customer arrives from the Unity dashboard the URL carries identifying parameters. The technical design of record defines them as: Cid (empty), Pid (organisation Id), fld2 (email), fld3 (name), fld4 (product type) and fld5 (the literal uDash). Both PRDs document an older, different scheme — fld1 for email, fld2 for the organisation — and are stale. Trust the TDD and the live URLs, not the PRDs.

The shell stores those parameters in sessionStorage under the key growParams the first time it sees them on the home page, and replays them onto the Contact Us URL if the customer navigates there without them. That mechanism exists because phase two moved the home page away from Contact Us, and without it most cases would have been created without an account. Genesis also strips the parameters when it bounces the customer through login, which is the same problem arriving by a different route.

# 4. How a customer gets an account

There is no Salesforce self-registration and no Salesforce password. All identity is Unity ID, brokered by Genesis through an OAuth client named ironsrc-sf-community. Salesforce sees the result through an Auth Provider, and the Auth Provider calls GrowthExternalRegistrationHandler.

**What the registration handler does, in order**

**1.** Splits the name attribute from Genesis on the first space into first and last name.

**2.** Looks up the Account named Unity Users — the umbrella account that placeholder contacts hang off.

**3.** Looks up the profile Customer Grow Community Login User.

**4.** Looks for an existing User with this email address on that profile. If one exists it is returned and nothing else happens — this is the normal path for every visit after the first.

**5.** Otherwise looks for a Contact with this email whose Account division is UnityAds, MobileCore or Tapjoy, ordered by division descending. That ordering means UnityAds wins, then Tapjoy, then MobileCore.

**6.** If no such contact exists, it creates one under Unity Users, stamping userId__c with the Genesis identifier.

**7.** If a contact was found but has no userId__c, it backfills it.

**8.** Creates the User linked to that Contact, with fixed defaults: time zone America/Los_Angeles, locale en_US, UTF-8, English.

**When it fails, it fails silently.** The whole method is wrapped in a try/catch that writes an ErrorObject__c record and returns null. Returning null from createUser means the customer gets a generic login failure with no explanation. If someone cannot log in and nothing is obviously wrong, ErrorObject__c is the first place to look.

**updateUser is empty.** The method exists to satisfy the interface and its body is commented out. Nothing that changes in Unity ID after the first login — name, email — ever propagates into Salesforce.

**The umbrella account, and the batch that cleans up after it**

A customer can perfectly well exist in Unity ID and have no Contact under a real Account — they may never have opened a ticket, or their contact may sit under a division the handler does not search. Rather than block them, the handler parks a new Contact under Unity Users so they can log in and use the site.

MatchContactBatch is the corrective mechanism. It runs daily, in chunks of five, over every Contact sitting under Unity Users that has a userId__c. For each one it looks for a real contact with the same Genesis user Id, and where it finds one it merges the two — keeping the real contact, moving the account across, and repointing the placeholder contact's Cases onto the matched account. Contacts with no match are left alone and picked up again the next day. The batch writes a CSV summary of what it did.

# 5. Who can see which case — the whole chain

This is the part to understand before touching anything. There are two independent mechanisms and they do not agree with each other.

**Mechanism one — what the portal actually enforces**

Every controller is declared without sharing, so Salesforce applies no record-level filtering at all. Scoping is done by a WHERE clause the developer wrote. CustomerPortalCasesController.getCases builds it dynamically and always includes these four conditions:

| **Condition** | **Meaning** |
|---|---|
| Customer_s_Email__c = the user's email OR Additional_Recipients__c LIKE %the user's email% | The identity test. It is a string comparison on email, not a Contact relationship. Being on the additional recipients list is enough to see a case you did not open. |
| internal_case__c = false | Internal tickets never appear. |
| RecordType.DeveloperName IN (Mobile_Support, Mobile_Demand_Support, Tapjoy_Support, Finance_Support, Fraud_Claim, Unity_Support) | Six record types. Anything else is invisible to the portal no matter who owns it. Fraud Claim was added after launch when the Fraud team agreed to expose their cases. |
| Origin != 'onBoarding' | Onboarding cases are excluded. |

The detail page repeats the same test in verifyUserPermission before it will return a case, add a comment, attach a file, close the case or write a CSAT rating. Fail it and the customer gets "User has no access to Case record."

**Mechanism two — the sharing set, for everything else**

Salesforce Files and attachments do use the platform's own permission model, so real record access has to exist too. That is what this chain is for:

  - > **Step 1.** A community user is created and the platform event New_Community_User__e is published, carrying the customer's email and the new Contact Id.

  - > **Step 2.** The flow Case - Update Sharing Contact - PE subscribes to it and updates every Case whose Customer_s_Email__c equals that email, setting Sharing_Contact__c to the Contact Id.

  - > **Step 3.** The sharing set named Cases grants Read on any Case whose Sharing_Contact__c matches the running user's Contact, to the profiles Customer Community Login User and Customer Grow Community Login User.

**The consequence worth knowing:** the two mechanisms can disagree. The case list is filtered by email in Apex; file access is granted by Sharing_Contact__c. A case created after the user's first login, or a case whose Customer's Email was edited later, will appear in My Requests but may have no Sharing_Contact__c — so the customer sees the case and cannot open its attachments. If someone reports "the ticket is there but the file will not download", that is the cause.

# 6. Submitting a request — how a form becomes a Case on the right account

**First, a warning about which code is live.** There are two nearly identical Contact Us stacks. The shell renders hcContent, which calls HelpCenterContactUsController — that component set is inherited from the predecessor Help Center site and is around 918 lines. There is also customerPortalContactUs calling CustomerPortalContactUsController, about 830 lines, a clone made for this site and exposed to Experience Builder so it can be dropped onto a page directly. Both exist in production. Before you change anything on this form, open the page in Experience Builder and confirm which component is actually placed on it, because editing the wrong one produces no effect and no error.

**The matching cascade**

The form does not ask the customer who they are. It works it out, in this order, stopping at the first hit:

| **#** | **Try** | **Detail** |
|---|---|---|
| 1 | Opportunity by company platform hash | Company_Platform_Hash__c matches the Cid parameter, with the division and department implied by the chosen category. Returns the Account. |
| 2 | Opportunity by platform hash | Same, on Platform_Hash__c against Pid. The hash is a hashed BI Opportunity value — an unusual design that predates the portal. |
| 3 | Contact by email, division and department | Contact.Email__c with Department1__c and Division__c matching the category. Ordered by the account's last-month revenue descending, so the largest account wins a tie. |
| 4 | Contact under the umbrella account | Contact.Email__c under Unity Users. If found, the case is created against that contact and the default account. |
| 5 | Lead | By company platform hash, then platform hash, then plain email, each with department and division. A matching lead is converted. |
| 6 | Hardcoded default account and contact | Two literal Ids in the class, switched by ENV.isProductionOrg(). In production, Account 0010N00005Ecpy3QAB and Contact 0030N00003LwSZhQAN. |

**Note the email field changes between steps.** The registration handler matches contacts on the standard Email field; the Contact Us cascade matches on the custom Email__c. If those two fields disagree on a contact record, the customer can be recognised in one place and not the other.

**What determines the record type**

Three chained custom metadata types drive the whole form. The customer picks a category, then a sub-category, then an issue type; each level filters the next, and the issue type — or failing that the category — supplies the Case record type by developer name.

| **Category (Label EN)** | **Division** | **Department** | **Record type** | **Sub-category list** |
|---|---|---|---|---|
| ironSource Ads Monetization | MobileCore | Publisher | Mobile_Support | ironSourceNetworkMonetizationSubCategories |
| ironSource Exchange | Video | Advertiser | Unity_Support | ironSourceExchangeSubCategories |
| Tapjoy Offerwall | Tapjoy | Publisher | Tapjoy_Support | TapjoyOfferwallSubCategories |
| Unity Ads Monetization | UnityAds | Publisher | Unity_Support | unityAdsMonetizationSubCategories |
| Unity Ads User Acquisition | UnityAds | Advertiser | Unity_Support | unityAdsUserAcquisitionsSubCategories |
| Unity Exchange | UnityAds Brands | Advertiser | Unity_Support | unityExchangeSubCategories |
| Unity LevelPlay Mediation | MobileCore | Publisher | Mobile_Support | unityLevelPlayMediationSubCategories |
| Unity Playworks | MobileCore | Advertiser | Mobile_Support | unityPlayworksSubCategories |
| Unity AdQuality | MobileCore | Publisher | Mobile_Support | unityAdQualitySubCategories |
| ironSource Ads User Acquisition | MobileCore | Advertiser | Mobile_Demand_Support | Inactive — sunset |

Every category also carries a Chinese label, so the form is bilingual. There are 49 sub-category records and 214 issue-type records behind these ten categories; the issue type is where the record type is finally decided when it differs from the category default.

After matching, the controller looks up the app by Appkey__c on Internal_App__c for publisher-side submissions, finds the first active Case assignment rule and applies it, and attaches any files the customer uploaded by linking their ContentVersion records. The form is protected by Google reCAPTCHA v2.

# 7. Knowledge on the portal

**Which articles appear**

Every Knowledge query in every controller carries the same two conditions and no others:

*PublishStatus = 'Online' AND IsVisibleInCsp = TRUE*

**That covers logged-in customers only.** For an anonymous visitor to see an article, the article must also have Visible in Public Knowledge Base ticked — the IsVisibleInPkb channel. That is enforced by the platform rather than by the query, which is why it was discovered late and by accident. If an article is visible to a signed-in customer and invisible to a guest, that checkbox is the reason.

The intended scope is the External record type only, published, latest version, with a category set. Filtering is done on the article's own multi-picklists — Product__c, Department__c and Category__c — using contains, not on Salesforce Data Categories. There are no Data Category Groups involved anywhere.

**How the product navigation maps to articles**

Two custom metadata types define the whole taxonomy. Portal_Content_Type__mdt holds the top level; Portal_Product__mdt holds the products beneath it and, crucially, the two filter values that select articles.

| **Portal product** | **Product filter** | **Department filter** | **Content type** |
|---|---|---|---|
| **Monetization — content type filter value Supply** | | | |
| LevelPlay | LevelPlay | Supply | Order 1. The business decided to stop calling this Mediation. |
| AdQuality | AdQuality | Supply | Order 2. |
| UnityAds Monetization | UnityAds | Supply | Order 3. Page API name UnityAds-Monetization. |
| ironSource Monetization | ironSource | Supply | Order 4. Page API name ironSource_Monetization — note the underscore where the others use hyphens. |
| Unity Offerwall Monetization | Tapjoy | Supply | Order 5. The portal label says Offerwall; the article filter value is Tapjoy. |
| **User Acquisition — content type filter value Demand** | | | |
| UnityAds User Acquisition | UnityAds | Demand | Order 1. |
| iAds User Acquisition | ironSource | Demand | Order 2. Currently inactive, so it does not render. |
| Unity Offerwall User Acquisition | Tapjoy | Demand | Order 3. |

**The mapping to remember:** Monetization means Department = Supply, User Acquisition means Department = Demand, and the same product filter value appears on both sides. All eight products reuse the same three categories — General & Account, Platform, SDK — which is why filtering by category on the search page mixes Supply and Demand articles together. That is a known, unresolved design collision, not a bug in the code.

**Promoted articles**

The home page shows up to twelve articles, assembled in three passes. First, records in Promoted_Articles__c where Active__c is true, in Order__c sequence — these are the manually promoted ones and they always come first. Then, if there is room, the articles with the most likes, counted from Knowledge_Rating__c and excluding anything already promoted. Then, if there is still room, any published article to make up the number. Every pass re-applies the Online and IsVisibleInCsp test.

**Article ratings**

Each helpful / not-helpful click writes a Knowledge_Rating__c record with a Like__c or Dislike__c flag against the article. The portal shows the like count as "N found this article helpful". Dislikes are recorded but not displayed to customers, by design.

**The deduplication only works for signed-in users.** getUserRating finds an existing rating by CreatedById matching the current user, so a logged-in customer's previous vote is recognised and the buttons are disabled. A guest has no stable identity, so nothing stops repeated voting from an anonymous session. Likes and dislikes are also not mutually exclusive — liking and then disliking the same article leaves both records in place.

# 8. What you can change without touching code

This is the part of the design that aged well. Seven custom metadata types carry the configuration, and the developer explicitly moved the product lists out of the code and into metadata so the business could control them.

| **Type** | **Controls** |
|---|---|
| Portal_Content_Type__mdt | The two top-level sections. Fields: Label__c, Order__c, Filter_Value__c (Supply or Demand), Is_Active__c. Deactivate one and it disappears from the navigation. |
| Portal_Product__mdt | The products under each section. Product_Name__c and Product_Description__c are what the customer reads; Page_API_Name__c is the URL; Product_Filter__c and Department_Filter__c decide which articles the page shows; Content_Type__c is the parent. Adding a product is a metadata record, not a deployment. |
| Portal_Ecosystem_Link__mdt | The Unity ecosystem tile strip on the home page — Title__c, Description__c, Link__c, Order__c, Is_Active__c. |
| Support_Community_Case_Status__mdt | How Salesforce case statuses are collapsed into the three buckets the customer sees. See below. |
| HelpCenter_Category__mdt | The ten top-level categories on the request form, each with its division, department, record type, English and Chinese labels, and the name of its sub-category list. |
| HelpCenter_SubCategory__mdt | 49 records. The second dropdown, filtered by the chosen category. |
| HelpCenter_IssueType__mdt | 214 records. The third dropdown, filtered by sub-category, and the final say on the Case record type. |

**The status buckets**

A customer never sees a Salesforce status. They see one of three labels, and the mapping is a metadata record:

| **Shown as** | **Default on?** | **Salesforce statuses it covers** |
|---|---|---|
| Open | Yes | New, On AM, On Tam, On R&D, TAM onRnD, On DevSupport, Confirmed Bug, On TamDevSupport, Re-Opened, In progress, Biz review, Research, Further Details Needed, Waiting Technical Support |
| Awaiting reply from customer | Yes | Pending Customer |
| Closed | No | Closed, Solved, Merged, Cancelled |

**This is the single most common source of "my ticket disappeared".** Any status not listed above maps to nothing, so the case vanishes from every filter — it is not hidden, it is unmatched. Confirmed was missing at one point and produced exactly that complaint. When support adds a new case status, this metadata has to be updated in the same change or tickets will silently drop out of the portal.

# 9. Public and private — the guest story

The site serves two audiences from the same components, and the split is the most argued-over part of the design.

| **Entry point** | **Behaviour** |
|---|---|
| support-ads.unity.com | Private. Redirects straight to Genesis for authentication. This is the link the Unity dashboard uses, deliberately, so that customers arrive identified and their cases land on the right account. |
| support-ads.unity.com/s/ContactUs | Public. The link that goes in emails, so a customer can raise a ticket without logging in. |
| Knowledge pages | Public, subject to the article carrying the public knowledge base channel (§7). |
| My Requests and request detail | Private. There is no anonymous view of a case. |

Three page variants exist to support this: a private home page, a public home page and Contact Us. The navigation and footer components read the session and render differently depending on whether the visitor is authenticated.

**What the guest user can actually touch**

The guest profile is Grow External Community Profile, on a Guest User licence. Its object access is deliberately tiny — Knowledge__kav, Knowledge_Rating__c and Promoted_Articles__c, and nothing else. No Case, no Account, no Contact.

**The failure mode to remember:** a guest also needs explicit Apex class access to every CustomerPortal class. Without it the page renders completely blank with no error — the components load and every wire adapter fails silently. This happened at launch and again when a controller was cloned. Any new controller needs the grant on both the guest profile and the community user profile before it will work.

# 10. Troubleshooting

**"A customer says their ticket is not in the portal"**

**1.** Check the record type. Only six qualify (§5). A case on any other record type will never appear.

**2.** Check the status. Read it against the three buckets in §8. An unmapped status makes the case invisible in every filter.

**3.** Check the email. Compare Case.Customer_s_Email__c and Additional_Recipients__c against the customer's User.Email exactly. Identity here is a string match, so a different address on the case is enough.

**4.** Check Internal Case and Origin. internal_case__c must be false and Origin must not be onBoarding.

**5.** Only then look at sharing. If the case is listed but a file will not open, that is the Sharing_Contact__c gap in §5, not a list problem.

**"The case was created on the wrong account"**

Almost always the matching cascade in §6 fell through to the umbrella account. The three causes seen in production, in order of likelihood: the URL parameters were lost before the customer reached the form, either by navigating within the site or by being bounced through Genesis login; the customer has no contact under the division implied by their chosen category; or a contact exists but under a different email field. The daily MatchContactBatch will repair the first case retroactively once the contact is matched, including repointing the cases — so check whether it has run before treating it as a defect.

**Known failures and what they mean**

| **Symptom** | **Cause** |
|---|---|
| A portal page loads completely blank | Missing Apex class access for the guest or community profile (§9). No error appears anywhere in the UI. |
| An article restricted to signed-in users is still reachable by a guest | Production CDN caching. There was a measured window of over thirty minutes where the old public version stayed served and stayed in the guest search index. Confirmed fixed in UAT; never confirmed closed on production. |
| A customer comment does not appear in the thread | Reported after launch and not resolved. The comment reaches Salesforce and is visible on the case feed, but does not render in My Requests. |
| The FIN chatbot does not appear for some users | A session cookie conflict — an active anonymous Intercom session blocks the identified one. Clearing the browser cache fixes it for an individual. The suggested proper fix is to call Intercom shutdown before booting the identified user. |
| Formatting, hyperlinks or embedded images are lost in agent replies | By design. The portal does not render HTML in case comments; images become attachments. |
| Something works in UAT and not in production | Take it seriously here. Production runs the Aura template with Lightning Locker enabled; the sandbox was LWR. The cookie footer radio button failed in production only for exactly this reason. |


# 11. Who to ask, and what to read

| **Topic** | **Person** |
|---|---|
| The product and the customer experience | Shani Kovalsky, Andrii Bosak and Aylin Lee. |
| The code — LWC, Apex, Auth Provider, guest access | Danill Rekov, who built all of it. |
| Account and contact matching, and why it works that way | Amir Weingrod and Yakov Asael designed it. |
| Salesforce configuration, the site, the custom domain, Genesis | Dror Diamant (outgoing) → Yakov Asael. |
| Knowledge content and article categories | Shani Kovalsky, Andrii Bosak |

**The documents worth reading, in order**

| **Document** | **Why** |
|---|---|
| [External Support Center TDD](https://docs.google.com/document/d/18C90Ek_nxZzouAl4sa8iWeP9QGxpkIccUWFlo_fe65E/edit) | The technical design of record. Authoritative on the URL parameters, the matching cascade and the daily batch. Read this before either PRD. |
| [User Scenarios for Accessing the External Support Center](https://docs.google.com/document/d/1yi67eyu2LHlFQ4VAD00b-sab9q7tV8a42F6mfUUvUtw/edit) | Short, and the clearest explanation of the umbrella account and why it exists. |
| [Customers Community (deck)](https://docs.google.com/presentation/d/1FNP8wN_bNuImqdH3NwFDwfmCIQYBH-TmwQYsni8mLm8/edit) | The best single overview — motivation, authentication model, permissions, and an unusually candid Challenges slide. |
| [PRD - Customer Community V2](https://docs.google.com/document/d/1Qb0ntdtvc-SY0D6v3ZulJ-ftL-ZZyAaALnpdP4N5h70/edit) | The Knowledge phase, page by page, with the article visibility rules and twelve open questions. Its URL-parameter table is stale — ignore that part. |
| [Community V2 Mapping](https://docs.google.com/spreadsheets/d/1T12jz1wJ0F_6_xxGljB10gVzjK1Uob0NU66cJRfxAyU/edit) | The product, department and case-status mappings, one sheet per custom metadata type. |
| [External Community Document](https://docs.google.com/spreadsheets/d/1Snemvd3JUW273T3CU6FDPGUDnxVhi429PtzwVEp5n1o/edit) | The master QA workbook — login, case creation, my cases, case details, the match batch, and the sandbox and production task lists. |
| [Customer Community Compliance Tracking](https://docs.google.com/spreadsheets/d/1MicsvGAv462kFnajG_mgDyskYL1TU-BJh2-MaE2ok1Y/edit) | The open compliance items in watch-out 11. |

**Next Step**

**Get the trade-compliance and legal-footer items owned.** Everything else on the §11 list is engineering debt that can be scheduled. Those two are the only items where a live customer-facing site is out of step with what Unity requires of it, and neither has an owner today.
