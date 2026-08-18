---
name: handbook-code-lookup
description: >
  Answers questions about the twelve documented Salesforce processes whose real answer lives in Apex, triggers or scheduled
  jobs rather than in the handbook — batch run times and cron schedules, what a class actually does, why an automation fired
  or did not fire, hardcoded thresholds and IDs, trigger order. Reads deployed source directly from the org (read-only) and
  cites it; optionally consults the SFDC-IS repository for git history. Use when the handbook is silent on a mechanism, when
  a handbook answer contradicts observed behaviour, or when someone asks what the code does.
  Trigger on: when does the batch run, batch schedule, scheduled job, cron, next invoice batch, next bill batch, what does
  the class do, which Apex, Apex class, trigger, is it hardcoded, why did it not fire, read the code, check the code,
  what does the code say, SFDC-IS, scheduler, Schedulable, batch size, governor limit in production.
---

# Handbook Code Lookup

Some questions about the twelve processes cannot be answered from the handbook because the answer was never in a document — it is in Apex, in a trigger, or in a scheduled job's cron expression. This skill reads the **deployed source from the org** and answers from it, with citations.

This exists because of a real failure: *"when does the next bill/invoice cycle attach to invoices and bills?"* The handbook describes the "waiting for next invoice/bill" flag and even links a document about the batch, but states no run times — so answering it from the handbook alone produces a confident guess. The run times are in two scheduled jobs, and they are readable.

## Operating Principles (apply to every response)

1. **Plan first** — name the class, trigger or job you are going to read and why, before reading it. Do not sweep the whole codebase.
2. **Read-only, always.** `soqlQuery` and `getObjectSchema` only. Never create, update or delete anything; never deploy, never modify Apex, never schedule or unschedule a job.
3. **Quote, don't paraphrase from memory.** Every claim about behaviour must come from source you actually retrieved in this session. Never reconstruct what a class "probably" does from its name — the name is a hypothesis, the body is the evidence.
4. **Separate WHAT from WHEN.** A batch class defines the logic; the **cron schedule is org configuration, not code**. Answering "when does it run" from the class body alone is the single most likely way to get this wrong. See *Schedules* below.
5. **Deployed code is the authority.** The org holds what is actually running. The Git repository may be ahead of it (unmerged/undeployed) or behind it (hotfixed in production). When they differ, say which you read.
6. **Self-review** before presenting: every behavioural claim traceable to retrieved source, every threshold quoted exactly, and anything you could not find stated as not found rather than assumed absent.
7. Always respond in **English**. End with a single, clear **Next Step**.

**Fit the use case, don't force the template:** a "when does this run" question wants the schedule and one line of context, not a code walkthrough. The hard rules — read-only, no paraphrase-from-memory, WHAT vs WHEN — are non-negotiable.

> Load `references/org-code-queries.md` for the validated query catalogue: reading Apex bodies, triggers, schedules, and the naming conventions that locate a class from a process name.
> Load `references/sfdc-is-repo.md` for the Git repository path — when it adds something the org cannot (history, blame, review context, undeployed work) and how to reach it.

## Where to read from

**Primary — the org.** Deployed Apex, triggers and job schedules are all readable by SOQL:

| Need | Object |
|---|---|
| Apex source | `ApexClass` — `Name`, `Body`, `ApiVersion`, `LengthWithoutComments` |
| Trigger source and status | `ApexTrigger` — `Name`, `Body`, `TableEnumOrId`, `Status` |
| **Job schedules** | `CronTrigger` + `CronJobDetail.Name` — `CronExpression`, `NextFireTime`, `PreviousFireTime`, `State`, `TimeZoneSidKey` |
| Flow existence / active state | `FlowDefinitionView` |

**Secondary — the `SFDC-IS` repository** (`unity/SFDC-IS` on Unity's internal GitHub Enterprise). Reach for it only when the question needs something the org does not hold: who changed a threshold and when, the review discussion behind a decision, or code that is not deployed yet. **It requires network access to an internal host and is unreachable from managed/remote Claude Code sessions** — see `references/sfdc-is-repo.md`. If it is unreachable, say so and answer from the org rather than stalling.

## Schedules — the part that gets answered wrongly

A `Schedulable` class contains **no schedule**. `BillCreationStandardCycleScheduler` is nine lines that construct a batch and run it; the cadence lives entirely in `CronTrigger`, set in Setup, and can be changed or paused without touching code.

So for any "when does X run" question:

1. Query `CronTrigger` joined to `CronJobDetail.Name` — job names are **free text typed by an admin**, so search loosely (`LIKE '%Invoice%'`) rather than guessing an exact name, and never assume the job name matches the class name. It frequently does not.
2. Report `CronExpression` **and** `TimeZoneSidKey` together. `NextFireTime` / `PreviousFireTime` are returned in **UTC** while the expression is evaluated in the job's timezone — quoting one without the other produces an answer that is wrong by hours.
3. **Check `State`.** `WAITING` is scheduled and live; `PAUSED` means it is not running at all. Several bill and invoice jobs in this org are `PAUSED` with fire times stranded in 2025 — reporting one of those as the live schedule would be a serious error.
4. A process can have several jobs, and a flow *and* Apex doing overlapping work. Report all of them rather than the first match.

## Worked example — the question that failed

*"When does the next bill/invoice cycle attach to invoices and bills?"*

Two scheduled jobs, both `State = WAITING`, timezone `Asia/Jerusalem`:

| Job | Cron | Meaning |
|---|---|---|
| `Attach to next invoice` | `0 0 20 2 */1 ?` | The **2nd of each month, 20:00** Jerusalem |
| `Attach to next bill` | `0 0 20 4 */1 ?` | The **4th of each month, 20:00** Jerusalem |

And the finding that matters more than the times: the handbook's Dispute tab carries a **"Live issue"** saying `PE_Deduct_Add_dispute_to_invoice_or_bill` is INACTIVE, and warns not to promise anyone their dispute will attach next cycle. That flow *is* inactive — but these two scheduled jobs are live and have been firing monthly. **The handbook's warning is therefore misleading**: the platform-event flow is not the only path, and attachment does still happen on a schedule.

This is the shape of answer this skill exists to give: the org state, the timezone, the job status, and an explicit note when it contradicts the handbook. When it does contradict, hand the contradiction to `handbook-refresh` so the reference file gets corrected.

## Finding the right class from a process name

Names in this org follow conventions worth exploiting — but confirm, never assume:

- **Batch + scheduler pairs:** `BillCreationBatch` / `BillCreationStandardCycleScheduler` / `BillCreationCustomCycleScheduler`. The `*_Batch` holds the logic; the `*_Scheduler` only launches it.
- **`FN_` prefix** for the finance integration family (`FN_InvoiceCreationBI_Batch`, `FN_StageBill_Batch`, `FN_UpdateInvoice_Batch`), each with a matching `_Scheduler`.
- **`Fraud_` prefix** for the fraud-dispute jobs the handbook names (`Fraud_DisputeCreateBatch`, `Fraud_DisputeInvoiceJob`, `Fraud_DisputeBillJob`).
- **One trigger per object**, plus vendor-injected `RHX_*` triggers from Rollup Helper — do not mistake an `RHX_*` trigger for team-written logic.
- A `LIKE '%Keyword%'` search on `ApexClass.Name` is the reliable way in. `*Test` classes are noise for behaviour questions but useful for understanding intended behaviour when the logic is dense.

## Answer format

1. **The answer**, up front, in the terms asked.
2. **The evidence** — class or job name, and the specific values (cron expression, threshold, field, filter) quoted exactly from what you read.
3. **What the handbook says**, if it covers the same ground — and explicitly whether the code agrees. A silent disagreement is the failure mode this skill was built to prevent.
4. **Caveats** — deployed-vs-repo, paused jobs, anything you could not locate.
5. **Next Step** — usually: hand a contradiction to `handbook-refresh`, or take a code change to the owning BSA.

## Boundary

- **This skill reads code; it does not change it.** No deployment, no Apex edits, no scheduling changes. A needed code change is a separate, reviewed piece of work.
- **It does not answer documented process questions.** How a dispute reaches an invoice, who approves what, what a field means → `handbook-processes`. Come here when that skill is silent or contradicted.
- **It does not update reference files.** Verifying handbook claims and proposing edits is `handbook-refresh`. Hand findings there.
- **It does not review code quality.** Flow review is `unity-flow-reviewer`; design work is `unity-tech-design` / `unity-sf-bsa`, both in the `unity-bsa` plugin.
- **It is not a SOX control** and produces no audit evidence — that is `unity-sox`.

End every response with the **Next Step**.
