![Unity SOX banner](./assets/banner.png)

# unity-sox

Unity's **SOX compliance toolkit for Salesforce**. It turns the team's quarterly SOX reviews into repeatable, script-driven, audit-ready workflows — access reviews and change-management review — each enforcing the exact tests, tabs, and evidence the auditors expect.

## How it works

- **Script-driven, not eyeballed.** Each skill runs deterministic Python scripts over the quarter's Salesforce exports — never approximating a diff or a classification by hand.
- **Evidence-based.** Results are validated against known data (self-comparison, prior-quarter sanity checks) before being reported as fact.
- **Judgment stays with you.** The skills flag exceptions and surface gaps; they present findings for the reviewer to decide, rather than deciding compliance outcomes themselves.
- **Distinct tests, never conflated.** Access review and change-management review use different objects, tabs, and Drive locations — each skill states its boundary explicitly.

## Skills

| Skill | What it does |
| --- | --- |
| [`sox-salesforce-access-review`](./skills/sox-salesforce-access-review) | Quarterly access review — Test 1 `ProfileStrongPermission` (User/Profile) and Test 2 `ProfilePermissionSets` (PermissionSetAssignment): compare quarters, flag new/changed/removed access, check against the Definition tab's approved lists, and surface genuine exceptions. |
| [`sox-manual-change-review`](./skills/sox-manual-change-review) | Change-management review of the Setup Audit Trail — classifies each quarter's configuration changes as Confident Relevant vs. Manual Review using a maintained whitelist (91.9% precision / 86.2% recall on real historical data). |
| [`sox-approver-matrix`](./skills/sox-approver-matrix) | Runs the quarterly approver-matrix control end to end — exports from Salesforce production, captures OCR-verified evidence screenshots, and builds one workbook per object (Bills/Invoice/Dispute/Credit) with Results/IPE/Modify-All/Custom-Settings/Approval tabs. |

## Install

- **Marketplace:** `/plugin marketplace add Yakov-Asael/unity-bsa-marketplace` → `/plugin install unity-sox`.
- **Cowork:** Customize → Skills → Create plugin → Upload plugin → the `unity-sox` `.plugin` file.

## Versioning

Current: **v0.2.0** (see `.claude-plugin/plugin.json`).

## Author

Unity Business Systems team.
