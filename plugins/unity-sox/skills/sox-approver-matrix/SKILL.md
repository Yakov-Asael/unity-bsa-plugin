---
name: sox-approver-matrix
description: Runs Unity's quarterly SOX approver-matrix control end to end — exports the approver matrix from Salesforce production, captures timestamped evidence screenshots, and produces one workbook per object (Bills, Invoice, Dispute, Credit) with Results / IPE / Modify All Permissions / Custom Settings / Approval tabs. Use this whenever someone wants to run, prepare, or produce the SOX control, the approver matrix control, IPE evidence, a Modify All permissions review, or the quarterly access review for auditors — including short or Hebrew phrasings such as "בקרת SOX", "בקרה רבעונית", "מטריצת מאשרים", "בקרת מטריצות מאשרים", "להוציא בקרה". Also use it when they ask what setup, permissions, or settings they need before running the control, or want to add an object, report, or approver to it. Do not use it for editing approver-matrix records, running ad-hoc SOQL against Approver_Matrix__c, debugging or reviewing approval Flows, building new Salesforce reports, or SOX work on systems other than Salesforce.
---

# SOX Approver Matrix Control

Produces one workbook per object, named `<Object> Approver Matrix - <Month> <Year>`,
each with five tabs: **Results**, **IPE**, **Modify All Permissions**,
**Custom Settings**, **Approval**.

Everything comes from **Salesforce production**. The pipeline drives a real browser and
takes real screenshots, because the audit evidence is the screenshot — including the
macOS menu-bar clock in it.

## Start here: show the person what they need

The single most common failure is someone running the control before their machine is
set up, then losing ten minutes to a half-broken run. **Before doing anything else, run
the preflight and show them the result:**

```bash
cd scripts && ./setup.sh && ./preflight.sh
```

`setup.sh` is idempotent (creates the Python environment, builds the OCR helper).
`preflight.sh` checks every prerequisite and prints the exact fix for anything missing.
Relay its output to the person — do not paraphrase away the fix instructions, they are
the useful part.

If this is a first run on a new machine, walk them through `references/setup.md`, which
explains each permission and why it is needed. Two of them are easy to get wrong:

- **Allow JavaScript from Apple Events** lives in Chrome's **macOS menu bar at the top
  of the screen** (View > Developer), *not* the ⋮ menu inside the browser window.
  People reliably look in the ⋮ menu first.
- **Screen Recording** and **Accessibility** need the app to be **quit and reopened**
  after granting, or they appear granted but do not work.

## Running the control

```bash
cd scripts && ./run.sh
```

Roughly ten minutes. Tell the person clearly, before it starts, that they must leave the
machine alone — no keyboard, no mouse, no Chrome — and park the pointer in a screen
corner. The run drives its own Chrome window and never navigates their tabs, but it
captures whole screens, so anything in front lands in the evidence.

`run.sh` archives previous screenshots and rebuilds everything. There is no resume mode,
on purpose: mixing screenshots from two runs would mean the evidence and the data
describe different moments, which is the one thing this control cannot tolerate.

If it stops partway, it will say what failed. Fix that, make sure the machine is idle,
and run it again.

## What the run guarantees

Rather than trusting that each step worked, the pipeline verifies itself and **fails
instead of producing wrong evidence**. Worth understanding, because it shapes how to
read a failure:

- **Every screenshot is OCR-verified before it is kept.** A shot that does not contain
  the expected page text is deleted and retried, then abandoned. A run that is
  interrupted yields *missing* evidence, never wrong evidence.
- **Report screenshot and CSV export happen back to back** (a few seconds apart), and
  `check_timing.py` fails the run if the gap exceeds the configured limit. The
  screenshot is what proves the rows in Results are what the report actually showed.
- **The numbers are read off the images, not the data.** `read_evidence.py` OCRs
  `Total Records` from each report screenshot and `Exported N records` from each
  Inspector screenshot, then reconciles them against the extracted data. Deriving one
  from the other would make the check meaningless.
- **Permission sets are discovered, not configured.** Whatever has Modify All on the
  run date shows up by itself.

When a check fails, work out whether the *evidence* is wrong or the *check* is wrong
before changing anything. Both happen. A check that is too strict is much cheaper than
evidence that is quietly wrong.

## Delivering to Google Drive

The output is `.xlsx` in `output/`. Upload each file to Drive and open it with Google
Sheets — tabs and embedded screenshots carry over. Drive cannot be written directly
from here.

## Changing what the control covers

`config.json` holds everything scope-specific: objects, report ids, approver names,
custom setting identifiers, org hosts, the timing limit. Adding an object or changing
approvers is a config edit, not a code change.

Read `references/extending.md` before editing it — it covers adding an object, changing
approvers, what happens when a new permission set gains Modify All (nothing: it is
picked up automatically), and how to find a report id.

## Environment notes

These are load-bearing and were each learned the hard way; `references/setup.md` has the
full list.

- The **Salesforce REST API is unusable from the browser session** (`INVALID_SESSION_ID`).
  Results come from the report's own CSV export with `isdtp=nv`, which is what stops
  Lightning from swallowing the export.
- **`screencapture` silently refuses any filename beginning with a dot.** It exits 0 and
  writes nothing.
- The report builder opens on **Outline**; the Filters tab is opened via JavaScript
  because macOS blocks synthetic mouse clicks here. The builder lives in a same-origin
  iframe and uses shadow DOM, so the opener walks frames and shadow roots.
- Screenshot resolution depends on which display Chrome is on. Both are valid evidence.

## Files

```
config.json              objects, report ids, approvers, org hosts, limits
scripts/setup.sh         one-time: Python env + OCR helper
scripts/preflight.sh     prerequisite checks with fixes
scripts/run.sh           the whole control
references/setup.md      permissions and settings, explained
references/extending.md  adding objects, changing approvers
output/                  finished workbooks
scripts/archive/         previous runs' screenshots
```
