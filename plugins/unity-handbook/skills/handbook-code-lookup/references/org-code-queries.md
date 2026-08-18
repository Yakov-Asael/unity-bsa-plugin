# Org code query catalogue

Every query below was executed successfully against Unity's production org (`newunityorgis`) on 17 August 2026. These are known-good shapes, not proposals.

**Read-only.** Nothing here writes, deploys, schedules or unschedules anything.

---

## 1. Apex source

The body of a deployed class is readable directly:

```sql
SELECT Name, ApiVersion, LengthWithoutComments, Body
FROM ApexClass
WHERE Name = 'Fraud_DisputeCreateBatch'
LIMIT 1
```

`Body` returns the complete source, comments included. This is the authoritative answer to "what does this class actually do", because it is what is deployed.

**Locate a class first, then read it** — bodies are large, so never fetch several at once speculatively:

```sql
SELECT Name FROM ApexClass
WHERE Name LIKE '%Dispute%'
ORDER BY Name
LIMIT 40
```

**Traps.**
- Fetching `Body` for many classes at once will blow up the response. Narrow to one or two by name first.
- `*Test` classes appear in every search. They are noise for "what does it do", but they encode *intended* behaviour and are worth reading when the production logic is dense or ambiguous.
- A class existing does not mean it runs. Check whether something invokes it — a trigger, a flow's Apex action, or a `CronTrigger` entry.

## 2. Triggers

```sql
SELECT Name, TableEnumOrId, Status, Body
FROM ApexTrigger
WHERE TableEnumOrId = 'Dispute__c'
```

`Status` is `Active` / `Inactive`. Confirmed on this org: `InvoiceTrigger` (Invoice__c) and `BillTrigger` (Bill__c), both Active — plus `RHX_Invoice`, `RHX_Bill`, `RHX_Dispute`.

**Trap:** `RHX_*` triggers are injected by the **Rollup Helper** managed package, not written by the team. Do not attribute team logic to them, and do not propose changing them.

## 3. Job schedules — the highest-value query here

Schedules are org configuration, **not code**. This is the query that answers "when does X run":

```sql
SELECT CronJobDetail.Name, CronExpression, NextFireTime, PreviousFireTime, State, TimeZoneSidKey
FROM CronTrigger
WHERE CronJobDetail.Name LIKE '%Invoice%' OR CronJobDetail.Name LIKE '%Bill%'
ORDER BY CronJobDetail.Name
LIMIT 30
```

All currently-scheduled jobs, soonest first:

```sql
SELECT CronJobDetail.Name, CronJobDetail.JobType, CronExpression, NextFireTime, State, TimeZoneSidKey
FROM CronTrigger
WHERE State = 'WAITING'
ORDER BY NextFireTime
LIMIT 40
```

**Traps — all four of these produce wrong answers if ignored.**

1. **Job names are free text typed by an admin.** They do not reliably match the class name, and they contain inconsistent spacing, tabs and ad-hoc time labels (`"FN_MassIssueInvoice_Scheduler\tAuto Invoice Monthly @ 02:00"`, `"BillCreationStandardCycleScheduler Every2Weeks at 12:00"`). Search loosely; never guess an exact name.
2. **`State` matters as much as the expression.** `WAITING` = live. `PAUSED` = not running. This org has several `PAUSED` bill/invoice jobs whose fire times are stranded in 2025 (`Bill_Feedback Daily @02:00`, `Invoice feedback from NS Daily @02:00`, `FN Bill Generate statement Monthly 10:00`). Reporting a paused job's cron as the live schedule is a serious error.
3. **Timezone.** `CronExpression` is evaluated in `TimeZoneSidKey` (mostly `Asia/Jerusalem` here), while `NextFireTime` / `PreviousFireTime` come back in **UTC**. Always report the expression together with its timezone; quoting a fire time alone is off by hours. Example: `Attach to next invoice` has `NextFireTime` `2026-09-02T17:00:00Z`, which is **20:00 on 2 September, Jerusalem**.
4. **The label in the job name can be stale.** `"BillCreationCustomCycleScheduler - Every 2 Weeks 12:00"` carries cron `0 0 12 16 */1 ?` — the 16th of each month, i.e. **monthly, not fortnightly**. Trust the expression, not the admin's label.

### Confirmed schedules, 17 August 2026

| Job (`CronJobDetail.Name`) | Cron | Timezone | State | Reading |
|---|---|---|---|---|
| `Attach to next invoice` | `0 0 20 2 */1 ?` | Asia/Jerusalem | WAITING | 2nd of each month, 20:00 |
| `Attach to next bill` | `0 0 20 4 */1 ?` | Asia/Jerusalem | WAITING | 4th of each month, 20:00 |
| `BillCreationStandardCycleScheduler Every2Weeks at 12:00` | `0 0 12 16 */1 ?` | Asia/Jerusalem | WAITING | 16th monthly, 12:00 (label says fortnightly — it isn't) |
| `BillCreationCustomCycleScheduler - Every 2 Weeks 12:00` | `0 0 12 16 */1 ?` | Asia/Jerusalem | WAITING | 16th monthly, 12:00 (same) |
| `Invoice_CreationBI_bi-weekly at 11:00` | `0 0 11 16 */1 ?` | Asia/Jerusalem | WAITING | 16th monthly, 11:00 |
| `Luna & AdQuality invoice creation` | `0 0 13 1 */1 ?` | Asia/Jerusalem | WAITING | 1st of each month, 13:00 |
| `FN_MassIssueInvoice_Scheduler Auto Invoice Monthly @ 02:00` | `0 0 1 10 */1 ?` | Asia/Jerusalem | WAITING | 10th of each month, 01:00 |
| `BillUpdateScheduler_Daily_11:00` | `0 0 11 ? * 1,2,3,4,5,6,7` | Asia/Jerusalem | WAITING | Daily, 11:00 |
| `Invoice_Update_BI_11:00_Daily` | `0 0 11 ? * 1,2,3,4,5,6,7` | Asia/Jerusalem | WAITING | Daily, 11:00 |
| `Bill_Feedback Daily @02:00` | `0 0 2 ? * 1-7` | Asia/Jerusalem | **PAUSED** | Not running; last fired Nov 2025 |
| `Invoice feedback from NS Daily @02:00` | `0 0 2 ? * 1-7` | Asia/Jerusalem | **PAUSED** | Not running; last fired Nov 2025 |
| `FN Bill Generate statement Monthly 10:00` | `0 0 12 10 */1 ?` | Asia/Jerusalem | **PAUSED** | Not running; last fired Dec 2025 |
| `FN Generate Bill Statement Net30 2200` | `0 0 12 22 */1 ?` | Asia/Jerusalem | **PAUSED** | Not running; last fired Dec 2025 |

### The paused jobs are intentional — do not re-raise them

Confirmed by the handbook owner: the four `PAUSED` jobs above were paused deliberately when the finance integration moved **from NetSuite to Workday**. They are legacy NetSuite-side jobs, which is why two of them carry `NS` in the name (`Invoice feedback from NS Daily @02:00`, `Bill_Feedback Daily @02:00`). Their last fire times in Nov–Dec 2025 mark the cutover, not an outage.

This is consistent with what `bills-invoice-sync.md` already documents: Workday is the current finance system, and NetSuite appears only as migration residue — accounts never migrated, bills carrying a stale NetSuite Id in the Workday Id field, and an error-log template still saying NetSuite when the batch calls a Workato recipe.

So: **a `PAUSED` state is not automatically a finding.** Check whether the job belongs to a superseded integration before reporting it. Genuinely unexplained paused jobs are still worth surfacing — the test is whether a decommission explains it, not whether the state looks alarming.

## 4. Flows

```sql
SELECT ApiName, Label, IsActive, ProcessType, TriggerType
FROM FlowDefinitionView
WHERE ApiName LIKE 'Dispute%'
ORDER BY ApiName
```

Use this to check whether a documented flow is actually live before explaining behaviour in terms of it. `COUNT(Id)` is **not** supported on this object — count client-side.

## 5. Naming conventions in this org

| Pattern | Meaning |
|---|---|
| `<Thing>Batch` + `<Thing>...Scheduler` | Logic in the `*Batch`; the `*Scheduler` only constructs and launches it (often under 10 lines) |
| `FN_*_Batch` / `FN_*_Scheduler` | Finance integration family — invoice/bill staging, BI sync, statements |
| `Fraud_*` | Fraud-dispute automation — `Fraud_DisputeCreateBatch`, `Fraud_DisputeInvoiceJob`, `Fraud_DisputeBillJob` |
| `Batch_*` | Older batch naming (`Batch_InvoiceCreationByDivision`, `Batch_BillsSubmitForApproval`) |
| `RHX_*` | Rollup Helper managed package — not team code |
| `*Test` | Test class; useful for intended behaviour, not for what runs |

## What the org still cannot tell you

| Need | Why not | Where instead |
|---|---|---|
| Who changed a threshold, when, and why | No history on `ApexClass` | The `SFDC-IS` repo — git log / blame |
| Review discussion behind a decision | Not in the org | Pull requests in `SFDC-IS` |
| Code written but not deployed | The org only holds deployed metadata | `SFDC-IS` branches |
| Validation rule messages, email alert recipients, page layouts | Not exposed by standard SOQL | Setup, or a metadata retrieve |
| Flow internals — the branch logic and thresholds *inside* a flow | `FlowDefinitionView` is header-only | Setup → Flow Builder, or the flow XML in `SFDC-IS` |

That last row is the strongest argument for repo access: **flow XML in the repository would make the handbook's approval thresholds machine-checkable**, and those are currently the largest unverifiable block. See `sfdc-is-repo.md`.
