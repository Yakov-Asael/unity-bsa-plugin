# Org verification query catalogue

The queries used to check handbook claims against the live Salesforce org. Every query in the **Validated** section below was executed successfully against Unity's production org (`newunityorgis`) on 17 August 2026 and returned usable results — they are known-good shapes, not proposals.

**Read-only.** Everything here is `soqlQuery` / `getObjectSchema`. Nothing in this file writes to the org, and no verification step ever should.

---

## Validated queries

### 1. Flows — existence and active state

The single highest-value check: the handbook documents ~28 flows for Dispute alone, and a deactivated flow is the most common cause of a handbook answer being actively wrong.

```sql
SELECT ApiName, Label, IsActive, ProcessType, TriggerType
FROM FlowDefinitionView
WHERE ApiName LIKE 'Dispute%'
ORDER BY ApiName
```

Check specific documented names directly:

```sql
SELECT ApiName, Label, IsActive
FROM FlowDefinitionView
WHERE ApiName IN ('PE_Deduct_Add_dispute_to_invoice_or_bill','Deal_Create_Supply_Deal_Dispute','Demand_Deal_Auto_Dispute_creation')
ORDER BY ApiName
```

**Traps.**
- `ApiName LIKE '<Process>%'` misses flows named for a different object that still belong to the process — `Deal_Create_Supply_Deal_Dispute` and `Demand_Deal_Auto_Dispute_creation` are Dispute-process flows that do not start with `Dispute`. Always also query the documented names explicitly, or a flow-count comparison will be wrong.
- `COUNT(Id)` is **not** supported on `FlowDefinitionView` (`field Id does not support aggregate operator COUNT`). Count rows client-side.
- `ProcessType` distinguishes screen flows (`Flow`) from `AutoLaunchedFlow` and legacy `Workflow`. A documented "flow" appearing as `ProcessType = 'Workflow'` and inactive is usually a retired predecessor, not the flow the handbook means — check for a similarly-named active record before reporting drift.

### 2. Approval processes

Documented approval chains are `ProcessDefinition` records, not flows. A handbook claim about "the approval process" is checked here.

```sql
SELECT DeveloperName, Name, Type, State, TableEnumOrId
FROM ProcessDefinition
WHERE Type = 'Approval' AND State = 'Active'
ORDER BY DeveloperName
```

`TableEnumOrId` gives the target object — that is how you confirm `Dispute_Approval_Process` and `Dispute_finance_approval` both still sit on `Dispute__c`.

**Limit:** this returns the process *header* only. The **step count, the approver fields and the entry criteria are not exposed** — every threshold claim ("up to four sequential steps", "skips when the approver field is blank") is Tier 3 and needs Setup or a metadata export.

### 3. Record types

```sql
SELECT DeveloperName, Name, SobjectType, IsActive
FROM RecordType
WHERE SobjectType = 'Dispute__c'
ORDER BY DeveloperName
```

Useful for the handover tab's "20 legacy record types" claim and for any record-type-driven routing.

### 4. Fields — existence

```sql
SELECT QualifiedApiName, Label
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'User' AND QualifiedApiName LIKE '%CRMA%'
```

Confirms a documented field exists on the object the handbook claims. This is how `Sales_CRMA_Admin__c` was confirmed as a **User field** — the Pipeline Summary tab is right about it, and it is easy to misread as a permission set.

For field detail — types, help text, and **picklist values** — use `getObjectSchema` with the object API name instead; picklist drift is a frequent cause of stale handbook content (Reason for Dispute, Bill Type, Task Type).

### 5. Permission sets and custom permissions — always both

```sql
SELECT Name, Label, IsCustom FROM PermissionSet
WHERE Name LIKE '%Fraud%' OR Label LIKE '%Fraud%'
ORDER BY Name
```

```sql
SELECT DeveloperName, MasterLabel FROM CustomPermission
WHERE DeveloperName LIKE '%Fraud%' OR DeveloperName LIKE '%Dispute%'
ORDER BY DeveloperName
```

**This pair is the canonical false-drift trap.** `Supply_Fraud_Dispute_Approver_1` / `_2` return **nothing** from `PermissionSet` and are present in `CustomPermission`. The handbook says "permission" and is correct. Never report an access grant as missing until both have been queried.

Note also that `Dispute_Fraud_Tapjoy_Approver_1` / `_2` *are* permission sets — similar names, different metadata type, different purpose. Match exactly.

### 6. Named people — still active?

```sql
SELECT Name, IsActive, Title, Email
FROM User
WHERE Name IN ('Noam Abutbul','Neta Ronen','Hagar Itzhak','Yakov Asael','Shani Kovalsky','Bar Damti','Tal Rahamim','Andrii Bosak','Danill Rekov','Amir Tapiro','Michael Marzitelli')
ORDER BY IsActive DESC, Name
```

**Duplicate-user trap.** This org returns **multiple User rows per person** — typically one populated record with a `Title` and one sparse duplicate on the same email. Several of the names above return two rows each.

Rules:
- Return every matching row; never `LIMIT 1`.
- Report someone as departed only when **all** their rows are `IsActive = false`.
- One inactive row beside an active one is normal and is **not** a finding.
- Watch for near-miss names (`shani kovalsky` on a non-Unity email is a distinct record) and for spelling that differs from the handbook (`Danill Rekov` vs the email `daniil.rekov@`).

### 7. Custom metadata rows

Custom metadata types referenced by the handbook (for example `Supply_Deal_Num_of_disputes__mdt`) are queryable as ordinary SOQL objects. **Confirm the exact API name via `getObjectSchema` before querying** — a wrong name returns a hard error, not an empty result, and is easy to misread as "gone".

---

## Not verifiable by SOQL — Tier 3

Report these as `NEEDS MANUAL CHECK`. Do not let them pass as verified, and do not infer them from adjacent Tier 1 results.

| Claim class | Why not | Where to check instead |
|---|---|---|
| Thresholds and branch logic inside a flow (`≥$50,000`, `under $1,000`, `>20% of monthly payout`, the reduced-amount formula) | Flow internals are not exposed via `FlowDefinitionView` | Setup → Flows, or a metadata retrieve |
| Approval step count, per-step approvers, entry criteria | `ProcessDefinition` exposes the header only | Setup → Approval Processes |
| Approver matrix **rows** (the actual names and bands) | Stored as records in the matrix object — queryable **only** once the object's API name is confirmed; the handbook does not state it consistently | Confirm the object with the owner, then SOQL it |
| Validation rule names and error messages | Not in standard SOQL | Setup → Object → Validation Rules |
| Email alerts, templates, recipients | Alert recipients not in standard SOQL | Setup → Workflow Actions / Email Alerts |
| Page layouts, button visibility, LWC behaviour | Not in standard SOQL | Setup / the portal itself |
| Business ownership, "known defect", "live issue", open next steps | Human facts, not org metadata | The named owner |

The handbook's highest-stakes content — the approval thresholds and the approver matrix — sits mostly in this table. Say so plainly in every report rather than implying broad assurance from a clean Tier 1 pass.

---

## Confirmed org state, 17 August 2026

Spot-checks run while building this skill, recorded as the baseline for the next refresh:

| Claim | Result |
|---|---|
| `PE_Deduct_Add_dispute_to_invoice_or_bill` is INACTIVE (handbook "Live issue") | ✅ Confirmed `IsActive = false` — the warning is real and still current |
| `Deal_Create_Supply_Deal_Dispute`, `Demand_Deal_Auto_Dispute_creation` active | ✅ Both `IsActive = true` |
| `Dispute_Approval_Process` + `Dispute_finance_approval` active on `Dispute__c` | ✅ Both `Active` |
| `Supply_Fraud_Dispute_Approver_1` / `_2` exist | ✅ As `CustomPermission` (not permission sets) |
| `Sales_CRMA_Admin__c` is a User field | ✅ Confirmed on `User` |
| `Dispute__c` record types | 5 active: `Demand_dispute`, `Fraud_dispute`, `SuperSonic`, `Supply_dispute`, `Video_Dispute` |
| Named owners/successors still active | ✅ All active — several with duplicate User records, as described above |
