# Pipeline summary

> Source: BSA Process Handbook, tab "Pipeline summary". Verbatim.

**Pipeline Summary**

**Process:** Pipeline Summary — everyone calls it "pipeline review" · **Built on:** Opportunity, four screen flows and two CRM Analytics dashboards on two Lightning home pages · **Date:** 10 August 2026 · **Business owner:** Amir Tapiro (Grow Sales Ops), with David Amar for enforcement · **Technical owner:** Dror Diamant → Noam Abutbul

*§1–2 what it is and where it lives · §3–8 how it is built · §9 troubleshooting · §10–11 where to look next.*

**Read this first.** There are two copies of this page. The Pipeline Management app and the Mobile Sales app both carry a home page with the same tabs and the same flows — but they point at two different CRM Analytics dashboards, Pipeline_Summary and New_Pipeline_Summary, and only the Mobile Sales copy has the Aura tab. Nothing in the org marks either as canonical. Establish which one the business actually uses before you change anything, because a fix applied to one will not appear on the other.

# 1. What this process does

The Pipeline Summary screens are the mobile sales org's pipeline-hygiene tool. Rather than opening opportunities one at a time, a seller or team lead gets an editable table of their open pipeline directly on the Salesforce home page and updates Stage, Start Date, the revenue potential and Next Steps inline, the way they would in a spreadsheet. It exists because pipeline data was going stale: quarterly alignment campaigns chase sellers to fill in the same four fields, and the completion rate is tracked and posted publicly. The Summary tab that sits alongside the tables is a CRM Analytics dashboard rather than a flow, and it behaves by entirely different rules — which is the single most common source of confusion.

**How it is used**

**1.** A seller or team lead opens the home page of the Pipeline Management app or the Mobile Sales app.

**2.** They pick a tab. Summary is a dashboard; the other four are editable tables of open opportunities, split by what is being sold.

**3.** What they see in those tables depends on two custom permissions — everything, their own team, or only opportunities they own (§7).

**4.** They edit inline: Stage, Start Date, the revenue or potential figure, whether the account is non-gaming, and Next Steps. Then they press Save.

**5.** They can export the current view to CSV.

**6.** Management reads the Summary, and Sales Ops chases whoever has not filled the fields in.

# 2. Where the screens live

| **Host page** | **App** | **Tabs, in order** |
|---|---|---|
| Pipeline_Management | Pipeline Management | Summary (the Pipeline_Summary dashboard) · Open Supply Opps - LP · Open Supply Opps - OW · Open Demand Opps. Four tabs, no Aura. |
| MobileSales | Mobile Sales | Summary (the New_Pipeline_Summary dashboard) · Open Supply Opps · Open Supply Opps - OW · Open Demand Opps · Open Aura Demand Opps — plus Home, Pipeline Review, Upsell Target Board, Churned Accounts Board and an Aura Apps Enrichment dashboard. This is the fuller version. |

  - > Both pages are Lightning home pages, not record pages, so there is no record context and nothing on them is driven by what the user was looking at.

  - > The Pipeline Management app is overridden onto the standard Home tab for a long list of profiles, so for many users this page is what Salesforce opens on.

  - > The tab titles are set on the flexipage, not in the flows. Renaming a tab does not touch the flow, and the header inside the table comes from a separate formula (§8).

# 3. The four tables — what each one shows

All four are the same component with different filters and different columns. Each one queries Opportunity, hands the results to a datatable, and offers inline editing and an export.

| **Tab** | **Flow behind it** | **What it lists, and the columns you get** |
|---|---|---|
| Open Supply Opps - LP | All_Open_Supply_Opps_LP_Data_Table_Screen (v33) | Open supply opportunities with little or no Offerwall revenue — the LevelPlay side of the book. Columns: Account, Name, Owner, Team, Division, Stage, Start Date, Age, Mediation Daily Revenue, Network Daily Revenue, Account's last 7-day TMR average, Non Gaming, Next Step, Last Modified. |
| Open Supply Opps - OW | All_Open_Supply_OW_Data_Table_Screen (v25) | The Offerwall side: Tapjoy division with Offerwall daily revenue above $100. Columns: Account, Name, Owner, Team, Sales Manager's Office, Stage, Go Live Date (Sales), Start Date, Age, OW Daily Revenue, Non Gaming, Next Step, Last Modified. |
| Open Demand Opps | Pipeline_Home_Page_Demand_Opps_Per_SM | Open demand opportunities per sales manager, excluding renewals, retention and operational records. Columns: Account, Name, Division, Owner, Stage, Start Date, Age, Go Live Date (Sales), Daily Potential, Account's last 7-day revenue average, Non Gaming, Next Step, Last Modified. |
| Open Aura Demand Opps ° | Pipeline_Home_Page_Aura_Demand_Data_Table_Screen (v13) | The Aura Advertiser book, added later and only on the Mobile Sales page. Scoped by the Aura Advertiser record type with no division or department filter. Not present in the metadata repo — read it in Flow Builder before changing it. |

# 4. What makes an opportunity appear

This is the section to open when someone says their opportunity is missing. Every table applies a common set of conditions and then adds its own. None of it is visible outside Flow Builder.

| **Condition — applied by every table** | **What it means and how it bites** |
|---|---|
| Stage is not Closed Won and not Closed Lost | Open pipeline only. Closing an opportunity removes it from the table immediately, which is how sellers clear their list. |
| Start Date is on or after today minus six months and a day | A rolling window, computed as ADDMONTHS(TODAY(),-6)-1. An opportunity with an old or empty Start Date silently drops out. Nothing anywhere explains why six months was chosen. |
| Belong to mobile sales is true | The master in-or-out test for the whole tool. If a seller's opportunities are not flagged as belonging to mobile sales, none of their pipeline appears — and this has been the cause of missing rows more often than anything else. |
| Record type is one of a hardcoded list | Each table names its record type IDs explicitly rather than looking them up. Adding a record type to the business means editing the flow. |
| App Go Live Date is empty (LP and OW only) | Live apps are excluded. An opportunity disappears from the supply tables the moment a go-live date is stamped. |

**And then the per-table conditions**

| **Table** | **Its own conditions** |
|---|---|
| Open Supply Opps - LP | Type is New Business, Upsell or Upsell Split. Offerwall daily revenue is under 1 or empty — that is what makes this the LevelPlay table rather than the Offerwall one. |
| Open Supply Opps - OW | Division is Tapjoy, Offerwall daily revenue is above 100, and Type is not Operational. Note the base query tests the account's division picklist while the two permission-scoped queries test the opportunity's own Division field — the same filter written two different ways. |
| Open Demand Opps | Type is not Renewal, not Retention, not Retention + Additional activity and not Operational. Daily Potential must not be empty. |

# 5. What blocks users, and why

| **Symptom** | **Cause** | **What to do** |
|---|---|---|
| A row cannot be saved, and the error is unhelpful | The datatable saves straight to Opportunity, so any validation rule on the object fires. The flow surfaces the platform error with no translation. | Open the same opportunity on its record page and try the identical edit — the real message appears there. |
| Operational opportunities cannot be edited or closed | Validation rules on Opportunity block operational records, and the flow simply fails. This is long-standing, was raised repeatedly and was never fixed. | The agreed workaround is to leave them alone and have them reassigned in bulk. Do not promise a fix without checking whether the validations can move. |
| No rows at all | Usually genuine: no opportunity meets the filters for that user. It is not an error state. | Work down §4 with one of their opportunities in hand rather than assuming a permissions problem. |
| The table is slow or looks truncated | The component is configured to display all rows with client-side pagination of ten. There is no query row limit set anywhere. | For a user with a very large book this is worth watching; nothing caps it today. |

# 6. Who sees what — the three visibility tiers

Each flow holds three separate Get Records elements that are identical except for one clause, and a decision picks between them on custom permissions. This is the whole security model, and it is worth knowing that it is implemented in the flow rather than by sharing.

| **Tier** | **Test** | **What they get** |
|---|---|---|
| Pipeline Owners | $Permission.Pipeline_Owners is true | The unfiltered query — the whole org's pipeline. Granted by the Pipeline Owners permission set. |
| Pipeline TLs | $Permission.Pipeline_TLs is true | Deal Team equals the user's Team (Reports) — their own team's pipeline. Granted by the Pipeline TLs permission set. |
| Everyone else | Neither permission | Only opportunities where the user is the owner, tested through the Am I the Opp Owner formula field. |

**Four things this model does not do**

  - > It does not govern the Summary tab. The dashboard is a CRM Analytics asset and obeys folder sharing, so anyone with analytics access sees the whole org regardless of their tier. This mismatch has already been raised as a surprise — the fix, if wanted, is a dedicated folder shared with a named list.

  - > It does not follow the role hierarchy. Team membership is read from Deal Team on the opportunity against Team (Reports) on the user, deliberately, because sales teams are reshuffled monthly and hardcoding was rejected.

  - > It does not fail safe in an obvious way. A team lead who has not been given the Pipeline TLs permission silently falls through to the owner-only tier and simply sees a short list, with no message explaining why.

  - > The permission names appear nowhere outside Setup. Nobody in the business calls them Pipeline Owners or Pipeline TLs; they say "TL" and "individual", so expect to translate.

# 7. What the Pipeline Summary CRMA actually is

The Summary tab is a single CRM Analytics dashboard called Pipeline Summary. It is not a flow, it does not read from a report, and none of the §4 flow filters apply to it. It renders one thing: a static 5-column by 8-row grid of forty plain numbers, on one page, with no charts. Every number is a separate query against one dataset.

| **What** | **Where it lives** |
|---|---|
| Dashboard | Pipeline Summary — one page, one grid, 40 number widgets and 2 filter panels. Mobile is not disabled. |
| Dataset | Pipeline Summary, API name Pipeline_Summary1 (id 0FbQv000000xGqLKAU). This is the only dataset any visible number reads from. |
| CRMA app | Growth_Automaton_App — the recipe writes the dataset into that folder, so folder access to the Growth Automaton app is what governs who can reach the underlying data. |
| Recipe | Reads Monthly_Revenue__c, Forecasted_Budget__c, Opportunity, Account and User. |
| Where to open it | [Analytics Studio](https://ironsrc.lightning.force.com/analytics/home) for the dashboard, [Data Manager → Datasets](https://ironsrc.lightning.force.com/analytics/dataManager/datasets) for the recipe and the dataset. |

**How to read the grid**

Rows are business lines, split into a Supply block and a Demand block. Columns are five ways of measuring the same line. The left-hand labels use trading names, not the picklist values stored in Salesforce — that mapping trips people up constantly:

| **Row label** | **Division__c value** | **Department__c** |
|---|---|---|
| **Net-Rev Supply block** | | |
| iAds + uAds | MobileCore, UnityAds | Publisher |
| OW | Tapjoy (OW = Offerwall) | Publisher |
| Total Supply | MobileCore, Tapjoy, UnityAds | Publisher |
| **Spend Demand block** | | |
| iAds + uAds | MobileCore, UnityAds | Advertiser |
| OW | Tapjoy | Advertiser |
| Aura | AppCloud (Aura is the trading name for AppCloud) | Advertiser |
| CTV | CTV | Advertiser |
| Total Demand | AppCloud, CTV, MobileCore, Tapjoy, UnityAds | Advertiser |

**Note the asymmetry.** Supply has three rows and Total Supply covers three divisions. Demand has five rows and Total Demand covers five. Aura and CTV exist on the Demand side only. If someone asks why there is no Aura supply number, that is why — it was never built.

# 8. Who sees what

There is no security predicate on the dataset and no sharing inheritance. Visibility is implemented inside the dashboard, and it works like this.

A hidden SOQL step named lens_7 runs on page load:

*SELECT Id, Sales_CRMA_Admin__c FROM User WHERE Id = '!{User.Id}' LIMIT 1*

Every one of the forty visible steps then carries the same three-branch OR clause, fed by that lookup:

| **Branch** | **What it means** |
|---|---|
| SalesManagerId_Consolidated = the running user's Id | You see rows where you are the sales manager on the account, the forecast or the opportunity. |
| Manager_ID_Consolidated = the running user's Id | You see rows belonging to anyone whose User.ManagerId is you — one level down the user hierarchy, not the full branch. |
| CRMAadmin = the running user's Sales_CRMA_Admin__c | The admin bypass. CRMAadmin is a recipe formula that returns the literal string 'true' on every single row. So if your User record has Sales_CRMA_Admin__c = true, this branch matches everything and you see the whole company. If it does not, the branch matches nothing. |

**To grant someone full visibility,** set Sales_CRMA_Admin__c = true on their User record. That is the whole mechanism. There is no permission set and no sharing rule involved.

**What this design means in practice**

  - > **It is only one level deep.** Manager_ID_Consolidated compares against User.ManagerId directly, so a director sees their own reports' rows but not their reports' reports. Roll-up beyond one level requires the admin flag.

  - > **The filter panels do not add security.** The two panels — Team and Sales Manager — sit on top of an already-filtered result. Picking another team in the panel cannot show you rows the OR clause excluded.

  - > **The dataset itself is wide open.** Because the scoping lives in the steps rather than in a security predicate, anyone with access to the Growth Automaton app can click Explore on Pipeline Summary and see every account, every sales manager and every number. If that is not acceptable, the fix is a security predicate on the dataset in Data Manager.

  - > **Every new step must repeat the clause.** All forty current cells do carry it — that was checked. But nothing enforces it. The moment someone adds a number without pasting in the OR clause, that cell shows org-wide figures next to correctly scoped ones, and it will look plausible.

**Three more people-filters upstream**

Separately from the dashboard, the recipe drops users who are not flagged as mobile sales. User.Belong_to_Mobile_Sales__c = true is applied three times — once on the actuals branch, once on the forecast branch and once on the opportunity branch. A sales manager without that checkbox disappears from the dataset entirely, not just from the view. This is the most common cause of "my whole team is missing".

# 9. Every cell, mapped

The five columns. Supply measures profit, Demand measures revenue; otherwise the two blocks are built identically.

| **Column** | **Measure** | **What it counts and how it is filtered** |
|---|---|---|
| Actual New closed-won | Supply: sum(SUM_Profit_180__c) · Demand: sum(SUM_Revenue_180__c) | Realised revenue inside the first 180 days after the account's go-live date. Filters: Division__c, Department__c, the measure > 0, Date_Consolidated inside the current fiscal quarter, plus the security clause. |
| Runrate | Supply: sum(RunRate_Supply) · Demand: sum(RunRateDemand) | Actuals so far plus a straight-line projection of the rest of the window. Same filters as the column to its left. |
| Weighted Pipeline | sum(Join4.SUM_Forecast_Weighted_Amount__c) | Forecasted Budget, weighted. Filters switch to the forecast side of the join: Join4.Opportunit.Account_Division_Picklist__c and Account_Department_Picklist__c, plus two date gates — Date_Consolidated and Join4.Start_Date_FB_Formula both inside the current fiscal quarter — plus the security clause. |
| Totals | C = A + B, where A = the Runrate measure and B = the Weighted Pipeline measure | Not an addition of the two cells to its left. It is its own query with a union-style filter: keep a row if it is a forecast row starting this quarter (Join4.FBorigin = 1 AND Join4.Start_Date_FB_Formula in this quarter) OR an actuals row with a positive measure. Division and Department are accepted from either side of the join. Row limit is raised to 25,000 on these steps; every other step is 2,000. |
| Weighted Pipeline (Next Quarter) | sum(Join4.SUM_Forecast_Weighted_Amount__c) | Identical to the third column with both date gates moved one fiscal quarter forward. |

**Step names, cell by cell**

If a number is wrong, this is how you find the query behind it. Open the dashboard in edit mode, find the step by name, and read its filters.

| **Row** | **Actual** | **Runrate** | **Wtd Pipe** | **Totals** | **Next Q** |
|---|---|---|---|---|---|
| **Net-Rev Supply** | | | | | |
| iAds + uAds | lens_6 | lens_6_2 | lens_6_5 | lens_6_28 | lens_6_15 |
| OW | lens_6_1 | lens_6_3 | lens_6_36 | lens_6_39 | lens_6_16 |
| Total Supply | lens_6_49 | lens_6_50 | lens_6_51 | lens_6_52 | lens_6_53 |
| **Spend Demand** | | | | | |
| iAds + uAds | lens_6_17 | lens_6_20 | lens_6_37 | lens_6_40 | lens_6_25 |
| OW | lens_6_19 | lens_6_22 | lens_6_38 | lens_6_41 | lens_6_26 |
| Aura | lens_6_59 | lens_6_60 | lens_6_65 | lens_6_67 | lens_6_66 |
| CTV | lens_6_44 | lens_6_45 | lens_6_46 | lens_6_47 | lens_6_48 |
| Total Demand | lens_6_54 | lens_6_55 | lens_6_56 | lens_6_57 | lens_6_58 |

**Which cells are clickable**

Six cells navigate to a saved lens when clicked; the other thirty-four do nothing. Only the two Totals rows are wired up, and only three of their five cells each.

| **Cell** | **Step** | **Opens the saved lens** |
|---|---|---|
| Total Supply → Actual | lens_6_49 | Current_Q_Total_Supply_Lens |
| Total Supply → Wtd Pipeline | lens_6_51 | Current_Q_Total_Weighted_Pipeline_Supply |
| Total Supply → Next Q | lens_6_53 | Next_Q_Total_Weighted_Pipeline_Supply |
| Total Demand → Actual | lens_6_54 | Current_Q_Total_Demand_Lens |
| Total Demand → Wtd Pipeline | lens_6_56 | Current_Q_Total_Weighted_Pipeline_Demand |
| Total Demand → Next Q | lens_6_58 | Next_Q_Total_Weighted_Pipeline_Demand |

**These six lenses live outside the dashboard JSON.** They are separate saved assets. If one of them is deleted or renamed the cell still renders its number but the click goes nowhere, and nothing on the dashboard will warn you.

**The filter panels**

Two panels sit above the grid: Team (bound to Team_Consolidated) and Sales Manager (bound to Sales_Manager_Consolidated). All forty steps have useExternalFilters and useGlobal switched on, so both panels facet the whole grid at once.

The dashboard also declares three further global filters that are never surfaced as a panel: Sales_Manager__c, User.Team_Reports__c and User.Name. They are inert as far as the user is concerned — leftovers from an earlier layout.

# 10. The recipe

The recipe is the interesting half of this process. It builds three independent branches, stamps each one with an origin flag, full-outer-joins them together on a shared grain, and then collapses the three sets of columns back into one set of "consolidated" fields. Understanding those four moves is enough to navigate the whole thing.

**The three branches**

| **Branch** | **Starts from** | **What happens to it** |
|---|---|---|
| A — Actuals | Monthly_Revenue__c | Filter to Date__c after 31 Dec 2024 → left join User on Sales_Manager__c → keep only Belong_to_Mobile_Sales__c = true → left join Account → drop any row where the Account has no Account_s_start_date_by_SM__c → aggregate to Account × Sales Manager × Division × Department × quarter, summing Profit_180__c and Revenue_180__c and taking MAX of fifteen Account snapshot fields → compute the run rates → stamp MRorigin = 1. |
| B — Forecast | Forecasted_Budget__c | Filter to Forecast_Date__c after 31 Dec 2024 and Division in the five → left join Opportunity (alias Opportunit) → left join Account → exclude Retention, Retention + Additional activity and Renewal types, exclude Closed Lost, require Forecast_Weighted_Amount__c > 0, and require either a go-live date more than 180 days old on a deal that is not yet Closed Won, or no go-live date at all → aggregate summing Forecast_Weighted_Amount__c → left join User on OwnerID__c → keep only mobile sales → stamp FBorigin = 1. A copy of this stream just before the aggregate is saved out as the second dataset, forecast_before_aggregate. |
| C — Opportunity / TMR | Opportunity | Left join Account → compute the quarter arithmetic and the two weighted-TMR measures → left join User → filter out Closed Lost, Retention and Renewal, require division in the five, require a positive TMR in this quarter or the next, and require either that the deal is not yet Closed Won or that it has no go-live date → aggregate → stamp OPPorigin = 1. |

**How they are stitched together**

  - > **JOIN4 — full outer,** forecast against opportunity, on (Opportunit.AccountId, User.Id, ForecastDateText) = (AccountId, OwnerId, StartDateQuarterDate). The right side is aliased Aggregate4.

  - > **JOIN5 — full outer,** actuals against the result of JOIN4, on (Account__c, Sales_Manager__c, DateText_to_date) = (Opportunit.AccountId, Aggregate4.OwnerId, Aggregate4.StartDateQuarterDate). The right side is aliased Join4.

**That is where the field prefixes come from.** A field with no prefix came from the actuals branch. Join4. means the forecast branch. Join4.Aggregate4. means the opportunity branch. Once you know that, the dashboard filter names stop looking arbitrary.

**The join grain is Account × Owner × quarter-start, and the quarter is a text string.** Each branch builds its own 'YYYY-MM-01' key by concatenating the year with a hardcoded quarter-start month, then casts it to a date. Because the join key is assembled rather than looked up, a mismatch produces silent duplicate rows rather than an error.

**The consolidated fields**

After the joins, each row has come from one, two or three branches. A set of formulas picks the right value by origin flag — all follow the same shape: if MRorigin = 1 take the actuals value, else if OPPorigin = 1 take the opportunity value, else if FBorigin = 1 take the forecast value.

| **Field** | **What it resolves to** |
|---|---|
| Date_Consolidated | The quarter this row belongs to. Almost every dashboard filter uses this rather than a source date field. |
| Sales_Manager_Consolidated | The sales manager's name — the field behind the Sales Manager filter panel. |
| Team_Consolidated | User.Team_Reports__c — the field behind the Team filter panel. |
| SalesManagerId_Consolidated | The sales manager's User Id — first branch of the security clause. |
| Manager_ID_Consolidated | That user's ManagerId — second branch of the security clause. |
| CRMAadmin | The literal string 'true' on every row — third branch of the security clause (§13). |
| DivisionConsolidated | Maps the raw picklist to the trading names used as row labels: MobileCore → iAds, UnityAds → uAds, Tapjoy → Tapjoy, AppCloud → Aura, CTV → CTV. Built, but the visible steps filter on raw Division__c instead. |
| Final_Start_Date | The opportunity start date if there is one, otherwise the forecast's start date. Used by exactly one visible cell — see §16. |

**The measures worth knowing**

| **Measure** | **How it is calculated** |
|---|---|
| SUM_Profit_180__c / SUM_Revenue_180__c | Straight sums of Profit_180__c and Revenue_180__c off Monthly Revenue. The "180" is the new-business window: revenue earned within 180 days of the account's go-live date. |
| NumOfDaysForRunRate | If Days_Left__c minus days_left_to_this_Quarter__c is positive, use days left in the quarter; otherwise use days left to 180. In other words, project only as far as the sooner of the two horizons. |
| RunRate_Supply | SUM_Profit_180__c + (Account.Last_7_days_net_revenue_avg__c × NumOfDaysForRunRate). |
| RunRateDemand | SUM_Revenue_180__c + (Account.Last_7_days_revenue_avg__c × NumOfDaysForRunRate). |
| SUM_Forecast_Weighted_Amount__c | Sum of Forecast_Weighted_Amount__c from Forecasted Budget, aggregated to owner × account × forecast quarter. |
| ThisQuarterWeightedTMR / NextQuarterWeightedTMR | The two longest formulas in the recipe. Both decide whether an opportunity's Weighted_TMR__c belongs to this quarter or the next, based on the opportunity start date, whether a go-live date exists, and whether the 180-day window has closed. Neither is displayed anywhere — see §16. |
| % Change previous period | Last seven days versus the seven before that, computed separately for Publisher (net of payout) and Advertiser (gross). Not displayed. |

**If a number looks wrong — the order to check it in**

**1.** Confirm which cell. Take the row label and the column heading, look the step name up in §14, and open that step in the dashboard editor.

**2.** Read the step's filters against §14. Check the division list, the department, the date field being gated and whether the measure > 0 clause is present.

**3.** Check the running user. Does their User record have Sales_CRMA_Admin__c set? Are they the sales manager or that person's manager on the rows they expect? Is Belong_to_Mobile_Sales__c true?

**4.** Check the account. Does it have Account_s_start_date_by_SM__c populated? Without it the account contributes nothing to the Actual and Runrate columns.

**5.** Check the recipe ran. Data Manager → Recipes shows the last run and its status. Numbers frozen since yesterday almost always mean a failed run rather than a logic bug.

**6.** Only then look at the formulas. Run the same filters as a lens on Pipeline_Summary1 and compare — if the lens agrees with the cell, the problem is upstream in the recipe, not on the dashboard.

**What to fix first**

**Next step:** decide with Sales Ops whether the dataset needs a security predicate. Everything else on the §16 list is tidy-up that can wait; that one is the only item where the current design and the intended design differ in a way an auditor would care about.

# 11. FAQ

**Check these five first:** (1) Which page is the user on — Pipeline Management or Mobile Sales? (2) Does the opportunity have Belong to mobile sales ticked? (3) Is its Start Date within the last six months? (4) Does the user hold Pipeline Owners or Pipeline TLs? (5) Is it an Operational opportunity?

| **Symptom, in the user's words** | **Cause and fix** |
|---|---|
| "She doesn't see the opportunity in pipeline review." | Work down §4 in order with that specific opportunity open. In practice it is nearly always one of three things: Belong to mobile sales is not ticked, the Start Date is older than six months or empty, or a Go Live Date has been stamped on the app. Permissions are the last thing to check, not the first. |
| "I see everyone's opportunities, not just my own." | The user holds the Pipeline Owners permission. If that is wrong, remove the permission set. If they are describing the Summary tab rather than a table, that is expected and different — the dashboard is not governed by these tiers at all (§7). |
| "Why does she see the whole org on the Summary but only her own rows in the tables?" | Because they are two different technologies. The tables filter in the flow; the Summary is a CRM Analytics dashboard governed by folder sharing, and that folder is shared broadly. To restrict it, the dashboard needs its own folder shared with a named list. |
| "Can I filter the table to just my opportunities?" | Type your own name into the search box above the table — it filters the rows already loaded. There is no separate owner filter, and for a Pipeline Owner this is the only practical way to narrow a very long list. |
| "Are you able to help with the operational opps that we cannot update?" | Known and unresolved. Validation rules on Opportunity block operational records and the flow fails when it tries to save. The agreed answer is to leave them and have them reassigned in bulk rather than editing them here. |
| "I tried to move an opp to closed-lost and got an error when saving." | The datatable writes directly to Opportunity, so it is a validation rule firing, and the message the component shows is rarely the useful one. Reproduce the same edit on the record page to see the real error, then fix the data. |
| "The numbers on the Summary don't match what I see in the table." | Expected. The Summary is a CRM Analytics dashboard built on its own recipe with different filters and different sharing; the table is a live SOQL query with the filters in §4. They were never designed to reconcile. Say so plainly rather than trying to make them agree. |
| "Can I edit from the Summary drill-down?" | No. Drilling into a total from the Summary opens a report. Editing only happens in the pipeline review tables. |
| "The heading above the Demand table says Supply." | A copy-paste bug in the HeaderLabel formula (§8). Cosmetic, but it makes people think they are on the wrong tab. Worth fixing in the same pass as anything else in that flow. |
| "My opportunity vanished after I set a go live date." | Working as designed on the supply tables — they list opportunities where the app has no go-live date. Once it is live it is no longer open pipeline as far as this tool is concerned. |
| "Where is the export?" | The Export button sits above the table on every tab and produces a CSV of the view you are looking at, respecting your visibility tier. The download appears as a link under the button. |
| "Which page should I be using — Pipeline Management or Mobile Sales?" | Nothing in the org answers this. They carry the same flows but different Summary dashboards, and only Mobile Sales has the Aura tab. Ask Amir Tapiro, and once you have the answer, write it down — this guide is the first place it will have been recorded. |

*Escalation: anything about what belongs in the pipeline, which filters apply or who should see what goes to Amir Tapiro, who owns the requirements. Sales-side enforcement sits with David Amar. Salesforce configuration, the flows and the export go to Yakov Asael. Users report problems in #grow-sales-all; there is no dedicated support channel, and the requirements history lives in a direct message rather than anywhere searchable.*

# 12. Dashboards and reports

The Summary tab is the only dashboard in scope, and it exists twice. Beyond it, the sales playbook points sellers at two Opportunity reports that cover the same ground through list views instead — worth knowing, because a seller following the published playbook never reaches these screens at all.

| **Asset** | **Where** | **What it is for** |
|---|---|---|
| **DASHBOARDS — CRM Analytics, not Lightning dashboards** | | |
| [Pipeline Summary CRMA](https://ironsrc.lightning.force.com/analytics/dashboard/0FKQv00000013tVOAQ) | | |
| Pipeline_Summary | Summary tab of the Pipeline Management page | The original. Shows the org-wide totals — new supply, new demand, current and next quarter weighted pipeline — with drill-down into reports. |

*Nothing here is scheduled or emailed. There is also no report on the tool itself — no measure of how many opportunities are missing a Start Date or a Daily Potential, even though that completion rate is quoted in the team channel every quarter and is counted by hand.*

# 13. Related documents

| **Document** | **Type** | **Open this when…** | **Status** |
|---|---|---|---|
| **REQUIREMENTS — such as they are** | | | |
| [Changes on tapiro dashboards](https://docs.google.com/document/d/1QDkPmHFubi2h0TXQJQ9BH0oRIz08L4IwWlxSvS5h65c/edit) | Doc | You need the only written statement of what qualifies for the Pipeline Review table — owner belongs to sales, go-live date older than six months or empty, stage not closed. Also records that the Aura tab was added later. | Draft, never signed off — a one-page bullet list, and the entire written requirement for this build |
| [Pipeline Manager POC](https://docs.google.com/presentation/d/1ntaS5GVWgd-1F91lUavkL_-YwvWRFSBsYcsc9bvTDj4/edit) | Slides | You want to see what was originally pitched — a Summary plus per-team and per-seller views. Useful only for understanding intent. | Superseded — four slides of screenshots from the proof of concept |
| [tapiro dashboard tasks](https://docs.google.com/document/d/18hNzJbCfw2XGmDpp0PRJo6vYdk9DbWdILaOHGgYoips/edit) | Doc | You are tracing the wider dashboard family the Summary tab belongs to, and need to know it draws on a CRM Analytics recipe joining revenue and commission rather than plain reports. | Obsolete — an early task list |
| **ENABLEMENT AND POLICY** | | | |
| [Grow Ads Sales Lead & Pipeline Management - Jan 2026](https://docs.google.com/presentation/d/1L1hk2X8R7O_y4sV2_Xj9wEm9nV_nAhyPP3xoImS9suM/edit) | Slides | You need the stage weights behind every weighted figure, or the hygiene rules sellers were actually taught. The only enablement material that shows these screens, though it shows them as screenshots with no walkthrough. | Current |
| [Sales Manager Playbook 2025](https://docs.google.com/document/d/1ySa9qgIO5X4X7Wg9jqFMUYFKW7rWDnM-V-dG56pAW1g/edit) | Doc | A seller asks where they should be doing pipeline review. Note it sends them to list views and reports, not to these screens — a contradiction worth resolving. | Current, but describes a different interface |
| **EVIDENCE** | | | |
| [Current_Q_Total_Weighted_Pipeline_Supply](https://drive.google.com/file/d/1A7Ro-3mETBPlxJ4xRW6BSHEBGkVX2qb4/view) | CSV | You need to know what the export actually produces, because no document lists its columns. Four near-identical exports exist for current and next quarter, supply and demand. | Current as evidence, not a specification |

*The honest summary of the documentation is that there is almost none. No PRD, no technical design, no permissions document, no definition of the Summary metrics, and no record of who signed anything off. The filter rules, the six-month window, the meaning of Belong to mobile sales and the decision to scope teams by Deal Team were all agreed in a direct message between the business owner and the builder. That conversation is the real specification, it is in Hebrew, and it is not searchable by anyone taking this over — which is the strongest argument for keeping this guide current.*
