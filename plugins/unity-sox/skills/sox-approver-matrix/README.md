![SOX Approver Matrix banner](./assets/banner.png)

# sox-approver-matrix

Runs Unity's **quarterly SOX approver-matrix control end to end** — exports the approver matrix from Salesforce production, captures timestamped evidence screenshots, and produces one workbook per object with the audit tabs.

## What it produces

One workbook per object (`Bills`, `Invoice`, `Dispute`, `Credit`), named `<Object> Approver Matrix - <Month> <Year>`, each with five tabs: **Results**, **IPE**, **Modify All Permissions**, **Custom Settings**, **Approval**. All data comes from **Salesforce production**.

## How it works

- **Preflight first:** `cd scripts && ./setup.sh && ./preflight.sh` — idempotent setup + prerequisite checks that print the exact fix for anything missing.
- **Run the control:** `cd scripts && ./run.sh` (~10 min; the machine must be left idle — the run drives its own Chrome and captures whole screens as evidence).
- **Self-verifying — fails instead of producing wrong evidence:** every screenshot is OCR-verified before it's kept; report screenshot and CSV export are timing-checked back-to-back; totals are read off the images and reconciled against the data; permission sets with Modify All are discovered, not configured.
- **Config-driven scope:** objects, report ids, approvers, custom settings, org hosts, and the timing limit live in `config.json` — adding an object or approver is a config edit, not a code change (see `references/extending.md`).
- **Delivery:** outputs are `.xlsx` in `output/`; upload to Google Drive and open with Sheets (tabs + embedded screenshots carry over).

## Triggers

SOX control, approver matrix control, IPE evidence, Modify All permissions review, quarterly access review — including Hebrew phrasings (בקרת SOX, בקרה רבעונית, מטריצת מאשרים, להוציא בקרה).

## Boundary

Runs/produces the control only. **Not** for editing approver-matrix records, ad-hoc SOQL on `Approver_Matrix__c`, debugging approval Flows, building new reports, or non-Salesforce SOX work.

## References & scripts

- `references/` — `setup.md` (permissions/settings explained), `extending.md` (adding objects/approvers)
- `config.json` — objects, report ids, approvers, org hosts, limits
- `scripts/` — `setup.sh`, `preflight.sh`, `run.sh`, and the capture/OCR/verify pipeline
