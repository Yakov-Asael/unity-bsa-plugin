---
name: sox-manual-change-review
description: SOX change-management review of Salesforce Setup Audit Trail (SetupAuditTrail) data — classifies each quarter's configuration changes as relevant or needing manual review, separate from the profile/permission-set access-review tests. Use for reviewing this quarter's audit trail export, excluding listed users, looking up a change's Type from its Section, and flagging genuine SOX-relevant changes via a maintained whitelist of known Flow/Approval-Process/Validation-Rule names. Trigger on "change management review", "audit trail", "Setup Audit Trail", "SetupAuditTrail", "manual change review", or a Salesforce export with Date/User/Action/Section/Delegate User columns. This is a distinct skill from the SOX access-review skill (which covers User/Profile and PermissionSetAssignment) — don't conflate the two; they use different data, different tabs, and different Drive locations.
---

# SOX Manual Change Review (Setup Audit Trail)

Classifies a quarter's Salesforce configuration changes (from the Setup
Audit Trail) as `Confident Relevant` or `Manual Review` for SOX
change-management purposes. This is a single self-contained test — unlike
the access-review skill, there's no cross-quarter diff here; each quarter's
audit trail is independently classified.

## Schema and workflow — see references/change-mgmt-schema.md

Tab structure (`Query to Review new`, `IPE`, `Users to Exclude`,
`Section -> Type`, `Raw Data`, `Only Q<N>`, `Data Filtered`, `Q<N> Changes to
Review`), the quarter-month mapping, and the raw CSV export format (6 columns
only, day-before-month dates, occasional non-UTF-8 encoding) are all
documented there — read it before running anything, especially the
performance notes (this data source runs 50,000+ rows; see the specific
`read_only=True` and cell-styling gotchas that caused severe slowdowns during
testing).

## Relevance classification — see references/change-mgmt-relevance-rules.md

**Read this before touching the relevance logic.** It documents two
approaches that were tested against 2,203 real historical labels and
rejected: Type-based (10% accuracy) and generic financial-keyword matching
(47% precision). The approach that actually works — a maintained whitelist
of specific Flow/Approval-Process/Validation-Rule names — reached 91.9%
precision / 86.2% recall. Don't reinvent a keyword rule from scratch; it was
already tried on this exact data and shown not to work.

## Workflow

```bash
python scripts/change_mgmt_classify.py <raw_data_file> <exclude_users_file> \
    <section_type_file> references/change-mgmt-whitelist.json <output_xlsx> \
    --quarter Q2 --data-sheet "Raw Data"
```
`<raw_data_file>` can be a raw CSV export (Salesforce's native 6-column
format) or an xlsx workbook tab — the script handles both. The other three
file arguments can all point at the same master workbook if the user hasn't
provided separate files.

Output has two sheets: `Q<N> Data Filtered` (all in-scope rows after
exclusion and quarter filtering, green = Confident Relevant, orange = Manual
Review) and `Q<N> Changes to Review` (Confident Relevant rows only). The
script also prints a JSON summary including any `Section` values not found
in the `Section -> Type` tab — treat that as a real documentation gap to
flag explicitly, not something to silently default or guess a Type for.

## Whitelist maintenance is part of every run

After the user reviews this quarter's `Manual Review` bucket, ask which
names (if any) should be promoted into `references/change-mgmt-whitelist.json`
for next quarter. **Don't rebuild the whitelist from scratch each quarter —
it accumulates.** Persist confirmed names across quarters; a name that
doesn't happen to recur this particular quarter shouldn't be dropped, since
the same business process may come back next quarter.

## No live-Sheet cell editing

Same constraint as the access-review skill: no tool writes cells into an
existing/cloned Google Sheet. `Google Drive:copy_file` can clone the whole
sheet (all tabs) into a new file for the new quarter — do that directly. But
populating `Raw Data`, highlighting `Data Filtered`/`Q<N> Changes to Review`,
and updating the `Definition`-equivalent notes must be delivered as a
downloadable xlsx plus explicit instructions for the user to paste in by
hand.

## Archiving

Upload outputs to whatever Drive folder the user names as this quarter's
target, named `Change Management Review - Q<N> review <Year>` (or whatever
naming convention the user has established for this specific review — ask
if unclear, don't assume it matches the access-review skill's convention).
Source/target folders are quarter-specific and not fixed — ask each cycle
rather than reusing a hardcoded folder ID.

## Edge cases

- **No rows in scope for the quarter**: still produce the output file and
  say so clearly.
- **Unrecognized `Section` values**: report every one by name, not just a
  count — these are real gaps in the `Section -> Type` tab that need the
  user's attention, and some may turn out to be newly-relevant processes.
- **Large row counts**: always run the script — never approximate a
  classification by eyeballing the data. See the performance notes in
  references/change-mgmt-schema.md; this data source is large enough that
  naive approaches (non-read_only workbook loads, styling cells via a
  post-append lookup) will time out or take many minutes.
- **Surprising classification counts**: if the Confident Relevant count
  looks very different from prior quarters, treat that as a signal to
  double-check before reporting it as fact, the same way Test 2 of the
  access-review skill caught real bugs by validating against known data
  first — don't just report a number without sanity-checking it.
