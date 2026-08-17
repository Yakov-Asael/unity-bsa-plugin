# Handbook refresh runbook

How the BSA Process Handbook stays current. This is the team's standing process, not a suggestion — an unrefreshed handbook is worse than no handbook, because people trust it.

---

## Sources of truth, in precedence order

When two disagree, the higher one wins.

1. **The Salesforce org** — the only authority on configuration. Flow state, field names, picklist values, approval wiring, who is active.
2. **This repo's reference files** (`plugins/unity-handbook/skills/handbook-processes/references/*.md`) — what the skill actually answers from. This is the artefact that must be kept true.
3. **The source Google Doc** — [BSA Process Handbook](https://docs.google.com/document/d/1m_I4_JRg-PPTM-2z5zsWTa3O7qWPTJqDLJY8DJ_gDxc/edit) — the upstream narrative record and the original author's account.

**The repo is what ships.** A correction made only in the Google Doc changes nothing for anyone using the plugin. Every refresh must land in the reference files.

**When the doc and the repo diverge:** the repo is corrected from the **org**, not from the doc, and the divergence is noted in the PR so the doc owner can reconcile. Never copy a doc edit into the repo without verifying it against the org first — the doc is not configuration.

---

## Cadence

| Trigger | Scope | Owner |
|---|---|---|
| **Quarterly**, alongside the SOX review cycle | Tier 1 sweep across all twelve tabs: flow active state, approval processes, record types, named people | Handbook owner (Business Systems) |
| **Semi-annually** | One Tier 3 deep pass: approval thresholds and approver matrix rows re-confirmed with each process's business owner | Handbook owner + per-process owners |
| **A handbook answer was wrong** | The affected tab, immediately | Whoever hit it |
| **A documented process changes** (deployment touching Dispute, Deals, Credit Check, Bills/Invoice, GPS, the portal, Knowledge, CSAT, C360, GDRC, Handover, Pipeline Summary) | The affected tab, in the same sprint as the change | The BSA who made the change |
| **A named owner leaves or changes role** | Every tab naming them | Handbook owner |
| **A thirteenth process is added** | New reference file + routing table row | Proposing BSA |

Quarterly is the floor, not the whole plan. **The rule that actually keeps it current: whoever changes one of these twelve processes updates its reference file in the same PR as the change.** Scheduled sweeps catch what that rule misses; they are not a substitute for it.

---

## The refresh flow

1. **Branch** `feature/handbook-refresh-<yyyy-qn>` (or `feature/handbook-<tab>` for a single-tab fix) off `develop`.
2. **Run the drift check** — invoke the `handbook-refresh` skill for the tabs in scope. It is read-only against Salesforce; it produces the drift report and proposed edits.
3. **Resolve Tier 3 items with the named owner.** Do not guess a threshold, and do not carry a `NEEDS MANUAL CHECK` row forward silently two quarters in a row — escalate it instead.
4. **Apply the edits** to the reference files. Preserve each file's `> Source:` provenance header and existing structure; edit values in place rather than restructuring the file.
5. **Update the snapshot dates** — the tab's `**Date:**` line, and the snapshot date in `handbook-processes/SKILL.md` (two places: the *Staying honest about the source* section and the skill body intro). A refreshed file with a stale date makes the freshness caveat lie.
6. **Record the baseline** — update the *Confirmed org state* table in `org-verification-queries.md` with the new date and results, so the next refresh has a diff to work against.
7. **Validate:** `python3 scripts/validate_plugin.py`.
8. **PR into `develop`** using the repo template. Paste the drift report — that *is* the test evidence this repo's process requires.
9. **Review** by another BSA; the maintainer merges. Release to `main` and the version bump are the maintainer's, per `CONTRIBUTING.md`.

---

## Definition of done for a refresh

- [ ] Every Tier 1 claim in scope has a verdict traceable to a query that was actually run.
- [ ] No `DRIFTED` / `GONE` verdict rests on a single query — sibling metadata types were ruled out (`PermissionSet` **and** `CustomPermission`, `FlowDefinitionView` **and** `ProcessDefinition`).
- [ ] Every Tier 3 claim is either confirmed with its owner or explicitly listed as outstanding, with a name against it.
- [ ] Reference files edited in place; provenance headers intact.
- [ ] Snapshot dates updated in the tab **and** in `handbook-processes/SKILL.md`.
- [ ] Baseline table in `org-verification-queries.md` updated.
- [ ] `validate_plugin.py` passes.
- [ ] Drift report pasted in the PR.

---

## Adding a thirteenth process

The plugin is not limited to the original twelve. To add one:

1. Open a **New skill** issue describing the process — it is the brief, per `CONTRIBUTING.md`.
2. Write `references/<process>.md` following the existing files' shape: title, `> Source:` line, a header line naming business owner / technical owner / date, then what the process does, entry points, automation, known gaps, FAQ, and who to ask.
3. Add the routing row to `handbook-processes/SKILL.md` — the ask keywords, the file, and the current owner. **A file with no routing row is unreachable**; the skill routes only from that table.
4. Extend the skill `description` with the new process's trigger keywords.
5. Add the process to the plugin README's coverage list.

---

## When to retire a tab

If a process is decommissioned, do **not** delete the reference file — replace its body with a short "retired" note giving the decommission date, what replaced it, and where the history lives, and mark the routing row retired. People keep asking about retired processes for a long time, and a documented "this is gone, here is what replaced it" is a real answer. Silent deletion produces a confident "not in the handbook" instead.
