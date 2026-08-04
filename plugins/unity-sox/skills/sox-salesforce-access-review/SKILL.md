---
name: sox-salesforce-access-review
description: Quarterly SOX compliance review of Salesforce user access/permissions. Covers TWO distinct, independently-runnable tests — Test 1 "ProfileStrongPermission" (User/Profile-level) and Test 2 "ProfilePermissionSets" (PermissionSetAssignment-level). Use for starting a new quarter's review, comparing this quarter's export against last quarter's, flagging new/changed/removed rows, checking data against a Definition tab's approved-profile rules to find genuine exceptions, or archiving quarterly SOX files in Drive. Trigger on "SOX review", "quarterly access review", "new quarter", "RawData", "To Review tab", "permissions changed", "Definition tab", "approved profiles", "exceptions", "PermissionSetAssignment", or a Salesforce export with Profile.PermissionsX / PermissionSet.PermissionsX columns. SOX Change Management Review (Setup Audit Trail) is a separate skill ("sox-manual-change-review") — don't conflate the two.
---

# SOX Salesforce Quarterly Access Review

Two separate SOX compliance tests live in this skill. They share the same
overall pattern (compare quarters, check against a Definition tab's approved
lists, highlight exceptions) but run on different Salesforce objects, different
sheets, and different scripts. **They must not be conflated.**

| | Test 1: ProfileStrongPermission | Test 2: ProfilePermissionSets |
|---|---|---|
| Salesforce object | `User` / `Profile` | `PermissionSetAssignment` |
| Match key | `Id` | composite: `(Assignee.Username, PermissionSet.Name)` |
| Tab names | `Query`, `IPE`, `RawData`, `Definition`, `" To Review"` (leading space) | `Query to Review new`, `IPE`, `Raw Data` (space), `Definition`, `To Review` (no leading space) |
| Scripts | `compare_quarters.py`, `flag_exceptions.py` | `permset_compare.py`, `permset_exceptions.py` |
| Schema ref | `references/column-schema.md` | `references/permset-schema.md` |
| Definition/rules ref | `references/definition-rules.md` | `references/permset-definition-rules.md` |

**A third SOX test (Change Management Review, Setup Audit Trail data) lives
in a separate skill: `sox-manual-change-review`.** It was split out because
it's a genuinely different kind of check — no cross-quarter diff, different
Salesforce object, different tab structure — not a variant of the two tests
here. Don't pull its logic into this skill.

## Always confirm which test before running anything

If it isn't already 100% clear from the conversation which test the user
means, **ask before running any script or producing any output.** Don't guess
from a vague "run the SOX check" — the two tests use different data, different
sheets, and different Drive files, and mixing them up produces a wrong
compliance result, not just a wrong file.

## Shared constraint: no live-Sheet cell editing

No tool exists that writes cell values, formatting, or highlights into an
*existing* Google Sheet — cloned or otherwise. `Google Drive:copy_file` CAN
clone a whole Sheet (all tabs, all formatting) into a new file — use that to
create each quarter's new sheet from the previous quarter's. But populating
`Raw Data`/`RawData`, highlighting `To Review`, or writing into
`Definition` column E ("Action Needed") must all be done by the user, by hand,
following exact instructions this skill produces. Concretely, each quarter:

1. Clone the previous quarter's Google Sheet (`Google Drive:copy_file`) into
   the current quarter's target Drive folder, named for the new quarter (e.g.
   `ProfileStrongPermission- Q3 review 2026`). This is the one live-Sheet
   action this skill *can* do directly.
2. Everything else — new `Raw Data` rows, highlighted `To Review` content, and
   `Definition!E` annotations — gets delivered as (a) a downloadable xlsx with
   the correct highlighting already applied, for the user to copy values from,
   and (b) an explicit, line-by-line list of exactly which `Definition!E<row>`
   cells to update and with what text (see each test's Definition-annotation
   output below) — never a vague "update the relevant rows."

**Source/target Drive folders are not fixed** — the "previous quarter"
location and "this quarter's" target folder are quarter-specific and the user
will tell you both each cycle (e.g. Q1 lived in one folder, Q2 moved to a
newly-created, differently-named folder for both tests). Don't hardcode a
folder as permanent; ask if it's not clear which folder applies this quarter,
and don't assume last quarter's target is this quarter's target.

## Test 1: ProfileStrongPermission (User/Profile-level)

### Required inputs
1. Previous quarter's file — the tracking workbook (`RawData`, `Definition`,
   `" To Review"`, `Query` tabs) or just `RawData` exported as xlsx/csv.
2. Current quarter's file — same shape, this quarter's rows in `RawData` (or
   a bare single-sheet export — sheet name varies, pass `--curr-sheet`).

If the user gives a Google Sheet link, use `Google Drive:read_file_content`
or download as xlsx — don't try to eyeball a diff from raw text output.
**Verify both files' header rows match `references/column-schema.md`
exactly** before comparing; if they don't, stop and say what's different.

### Workflow
```bash
python scripts/compare_quarters.py <prev_file> <curr_file> <output_xlsx> \
    --curr-sheet "<sheet name>"   # defaults: sheet "RawData", key "Id", diff from column J
```
Prints new/removed/changed users and writes a highlighted `To Review`-shaped
workbook (yellow = changed, green = new). Then:
```bash
python scripts/flag_exceptions.py <data_file> <definition_source_file> <output_xlsx> \
    --data-sheet "<sheet name>"
```
Produces an `Exceptions` sheet (only genuine red-cell violations, approved
profiles already excluded) plus a copy of `Definition` for reference. See
`references/definition-rules.md` for the parsing/matching spec — don't skip
the parenthetical-suffix profile-name gotcha, it produces false positives if
matched as exact string equality.

### Presenting results
- The diff output file via `present_files` — what the user pastes into
  `" To Review"`.
- A plain-language summary: changed users (old→new value), new/removed users,
  and separately, the exception list with a note on whether each looks like a
  real problem or an obviously-benign account — let the user judge, don't
  decide for them.
- **Definition annotation list**: for every permission column with at least
  one exception, give the exact text: `Definition!E<row>` (permission name) →
  change to `"Q<N> <year>: flagged — <user> has this permission TRUE, not on
  approved list. Needs review."` List every one by name.

## Test 2: ProfilePermissionSets (PermissionSetAssignment-level)

### Required inputs
Same two-file pattern as Test 1, but sheet names differ (`Raw Data` not
`RawData`, `To Review` with no leading space) — **verify against
`references/permset-schema.md`, don't assume Test 1's tab names carry over.**

### The profile-mirror trap — read this before running anything
The vast majority of rows in this data are Salesforce's auto-generated
per-profile "mirror" permission sets (`PermissionSet.Name` like
`X00e0N000000JEu1QAG`), not genuine custom grants — in the real Q1 data this
was 96% of all rows. `permset_exceptions.py` resolves these back to a real
profile name automatically, but **only when the extracted Id is a confirmed
member of Test 1's `Profile.Id` list** — never trust an Id-shaped name that
doesn't actually resolve; route it to manual review instead of guessing. This
already caught one real bug in testing (see `references/permset-schema.md`)
and there's a live example of a confirmed-but-unresolvable-by-pattern
identity already documented there (`System Administrator Custom`) — check
that list before assuming a new unresolvable Id is the same kind of thing;
ask the user, don't assume.

### Workflow
```bash
python scripts/permset_compare.py <prev_file> <curr_file> <output_json> \
    --curr-sheet "Raw Data"
```
Reports new/removed/changed `(Assignee.Username, PermissionSet.Name)` rows
(JSON only, no highlighted workbook — pair with the exceptions script below
for the actual reviewable output).
```bash
python scripts/permset_exceptions.py <data_file> <definition_source_file> \
    <profile_lookup_file> <output_xlsx> --data-sheet "Raw Data"
```
`<profile_lookup_file>` is Test 1's `RawData` workbook (needed for the
profile-mirror resolution — this is the one place the two tests' data
actually cross-reference each other). Produces three sheets: `Exceptions`
(confirmed violations), `Manual Review Needed` (named-individual approved
lists, or unresolved Id-shaped permission-set names — don't treat these as
confirmed either way), and a copy of `Definition`. See
`references/permset-definition-rules.md` for the full matching spec,
including the Profile./PermissionSet. prefix-mismatch gotcha found in the
real Definition tab (register rules under both prefixes, don't assume it's
fixed in later quarters).

### Presenting results
Same shape as Test 1 (diff summary, exceptions with judgment calls flagged
rather than decided, Definition annotation list for column E) — plus always
report the `Manual Review Needed` count/contents separately from confirmed
exceptions, since those two categories mean different things (confirmed
problem vs. "I couldn't verify this automatically").

## Archiving

Upload outputs to whatever Drive folder the user names as this quarter's
target (see "Source/target Drive folders" above), named `<Test Name>- Q<N>
review <Year>` to match the existing naming pattern. Keep outputs flat within
a quarter's folder unless told otherwise.

## Edge cases (both tests)

- **No changes found**: still produce the output file and say so clearly —
  don't skip the deliverable just because nothing changed.
- **Header/schema mismatch** between quarters: stop and report the exact
  difference; don't force a comparison or silently adapt.
- **Large row counts**: always run the script — never approximate a diff or
  an exception check by eyeballing the data.
- **Surprising exception counts** (much higher/lower than expected): treat as
  a signal to double check the matching logic before reporting it as fact —
  during Test 2's build, an unvalidated assumption produced 581 false
  exceptions before three separate bugs were found and fixed by testing
  against known data first. Validate new/changed logic against a
  self-comparison (previous quarter vs. itself, expect zero diff) before
  trusting it against real new data.
