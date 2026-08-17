# Handbook Maintenance Policy

The governance rules for the [`unity-handbook`](../plugins/unity-handbook) plugin — who owns it, when it gets verified, and how a change reaches production.

This is the **policy**. The operational detail (exact queries, drift-report format, definition of done) lives with the skill that does the work: [`refresh-runbook.md`](../plugins/unity-handbook/skills/handbook-refresh/references/refresh-runbook.md) and [`org-verification-queries.md`](../plugins/unity-handbook/skills/handbook-refresh/references/org-verification-queries.md).

---

## Why this plugin needs a policy at all

Every other plugin in this marketplace encodes a *standard* — a template, a ruleset, a review bar. Standards change slowly and deliberately.

`unity-handbook` is different: it encodes **the current state of twelve production Salesforce processes**. That state changes every time someone deploys. The content was accurate on 9–10 August 2026 and starts decaying immediately, silently, and in the most dangerous way possible — the answers stay confident while the thresholds and approvers behind them move.

So the plugin ships with a maintenance obligation that the others don't have. **A handbook nobody refreshes is worse than no handbook**, because people trust it and stop checking the org.

---

## Ownership

| Role | Who | Responsibility |
| --- | --- | --- |
| **Handbook owner** | Business Systems team lead (currently @Yakov-Asael) | Owns the refresh cadence, chases outstanding manual checks, signs off releases |
| **Process owners** | Per the routing table in [`handbook-processes/SKILL.md`](../plugins/unity-handbook/skills/handbook-processes/SKILL.md) — Noam Abutbul, Neta Ronen, Hagar Itzhak, Yakov Asael | Authoritative on their tab's thresholds, approvers and known issues; confirm the Tier 3 claims |
| **Any BSA** | Everyone | Updates the affected reference file in the same PR as any change to a documented process |
| **Repo access** | Whoever administers the Claude Code environment | Optional: allowing `github.cds.internal.unity3d.com` unlocks flow-XML checking of the Tier 3 block from remote sessions |

---

## Source-of-truth precedence

When two disagree, the higher wins:

1. **The Salesforce org** — the only authority on configuration.
2. **The repo's reference files** — what the skill actually answers from. This is the artefact that must be kept true.
3. **The source Google Doc** — the upstream narrative record and the original author's account.

**The repo is what ships.** A correction made only in the Google Doc changes nothing for anyone using the plugin. Corrections come *from the org*, not from the doc — the doc is not configuration, and a doc edit is a claim to verify, not a fact to copy.

---

## The rule that actually keeps it current

> **Whoever changes one of the twelve documented processes updates its reference file in the same PR as the change.**

Everything below is a safety net for what this rule misses. It is not a substitute for it. A scheduled sweep three months later finds drift that a same-PR update would have prevented entirely.

Applies to any deployment touching: Dispute · Handover · Connect 360 · GDRC · Credit Check · Customer Community · Knowledge · CSAT · Deals · Pipeline Summary · GPS · Bills/Invoice Sync.

---

## Verification cadence

| Trigger | Scope | Owner |
| --- | --- | --- |
| **Quarterly**, alongside the SOX review cycle | Tier 1 sweep across all twelve tabs — flow active state, approval processes, record types, named people still active | Handbook owner |
| **Semi-annually** | Tier 3 deep pass — approval thresholds and approver matrix rows re-confirmed with each process's business owner | Handbook owner + process owners |
| **A handbook answer was wrong** | The affected tab, immediately | Whoever hit it |
| **A documented process changed** | The affected tab, same sprint | The BSA who made the change |
| **A named owner leaves or changes role** | Every tab naming them | Handbook owner |

Quarterly is the **floor**. Pinning it to the SOX cycle is deliberate: that review already pulls the team into the same objects and the same access questions, so the marginal cost is low and it won't get skipped.

### What "verified" is allowed to mean

The `handbook-refresh` skill sorts claims into tiers, and the distinction is the whole point of the policy:

- **Tier 1** (flow state, record types, field existence, permissions, active users) — checkable by SOQL, authoritative.
- **Tier 1b** (Apex logic, hardcoded thresholds, trigger status, **job cron schedules and paused/waiting state**) — readable from the org via `handbook-code-lookup`, authoritative for deployed code.
- **Tier 2** — the wiring, not the logic. Directional only.
- **Tier 3** (thresholds *inside flows*, approval step counts, approver matrix rows, validation messages, email recipients, ownership) — **not reachable by query at all.**

The handbook's most business-critical remaining content is Tier 3. A quarterly report that verifies thirty flow names and says nothing about the approval thresholds has **not** verified the handbook, and must not be presented as if it had. Outstanding Tier 3 items carry a named owner and must not roll forward silently two cycles in a row.

### "Not documented" usually means "not documented in prose"

The handbook carries what a human thought to write down. Batch run times, hardcoded thresholds and the reason an automation didn't fire were often never written anywhere — but they are readable in Apex and in `CronTrigger`.

Before recording a gap, check the code. Two findings from the first pass make the point:

- The Dispute tab describes the "waiting for next invoice/bill" flag and links a document about the batch, but states **no run times**. Two scheduled jobs hold them (`Attach to next invoice`, 2nd of the month 20:00; `Attach to next bill`, 4th, both Asia/Jerusalem). Answering that question from the handbook alone produced a confidently wrong answer in real use.
- That same tab's **"Live issue"** warns the flow applying these disputes is inactive, implying nothing attaches. The flow *is* inactive — and those two jobs are live and firing monthly. Verifying only the flow would have confirmed a misleading warning as correct.

So a refresh checks flows **and** the Apex/schedule behind them. A `NEEDS MANUAL CHECK` on something that was queryable all along is a process failure, not an acceptable outcome.

### Correcting a reference file without losing provenance

Reference files are preserved verbatim from the source handbook. When the org contradicts one, **do not overwrite the original sentence** — append a `> **Verified <date>:**` blockquote beneath it giving the confirmed state and what changed.

`handbook-processes` treats those notes as superseding the text above them. This keeps the original author's account intact while making sure nobody is answered from a claim the team knows to be wrong.

---

## How a change reaches production

Standard repo flow — see [`CONTRIBUTING.md`](../CONTRIBUTING.md).

1. Branch `feature/handbook-refresh-<yyyy-qn>` (or `feature/handbook-<tab>`) off `develop`.
2. Run the `handbook-refresh` skill for the tabs in scope. **It is read-only against Salesforce** and proposes edits rather than applying them. Delegate Tier 1b claims to `handbook-code-lookup` and fold its findings in.
3. Resolve Tier 3 items with the named process owner.
4. Apply the edits in place, preserving each file's `> Source:` provenance header.
5. **Move the snapshot dates** — the tab's `**Date:**` line *and* the snapshot date in `handbook-processes/SKILL.md`. A refreshed file with a stale date makes the freshness caveat lie.
6. Update the baseline table in `org-verification-queries.md`.
7. `python3 scripts/validate_plugin.py`.
8. PR into `develop`; **paste the drift report** — that is the test evidence this repo's process requires.
9. A teammate reviews; the maintainer merges and releases to `main` with the version bump.

---

## Hard rules

- **Never write to Salesforce from this plugin.** Verification is read-only, always. A drift finding is a documentation bug until a human decides otherwise; fixing production is a separate, deliberate change with its own review.
- **Never declare drift from a single query.** Salesforce names collide across metadata types — the handbook's `Supply_Fraud_Dispute_Approver_1` returns nothing from `PermissionSet` and exists as a `CustomPermission`. A false "this is gone" sends someone to change production.
- **Never let the skill silently rewrite reference files.** Proposed edits go through review like any other change.
- **Never write to Salesforce or to `SFDC-IS` from `handbook-code-lookup`.** It reads deployed Apex and schedules; it does not deploy, edit Apex, or change a job's cron. `SFDC-IS` is a production metadata repo — changes there reach Salesforce.
- **Report the schedule with its timezone and state.** A cron expression is evaluated in the job's `TimeZoneSidKey` while fire times return in UTC, and a `PAUSED` job is not running at all. Quoting one without the others is how a schedule answer goes wrong.
- **Never drop the freshness caveat**, even right after a refresh. It names the snapshot date; it does not claim staleness.
- **Never delete a retired tab** — replace its body with a decommission note. People ask about retired processes for a long time.

---

## Relationship to the SOX plugin

`unity-handbook` produces **no audit evidence**. It is documentation, not a control.

`dispute.md` describes the approval evidence that the [`unity-sox`](../plugins/unity-sox) approver-matrix control samples, and the two are easy to conflate. They are separate: SOX controls have their own scripts, tabs, evidence requirements and sign-off. When a drift check surfaces an access exception (a departed user still holding a permission, say), hand it to the SOX access-review owner — do not treat it as control evidence, and do not treat a clean SOX quarter as a verified handbook.
