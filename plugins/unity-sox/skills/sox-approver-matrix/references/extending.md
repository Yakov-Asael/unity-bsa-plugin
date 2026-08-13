# Changing what the control covers

Almost everything scope-related lives in `config.json`. Prefer editing that over
touching the scripts.

---

## Add an object to the control

Append an entry to `objects` in `config.json`:

```json
{
  "key": "dealpayment",
  "display": "Deal Payment",
  "sobject": "Deal_Payment__c",
  "report_id": "00OQv0000094e8AMAQ",
  "report_name": "Deal Payment Approver Matrix",
  "approvers": ["Eyal Kaner"]
}
```

| field | what it is | how to get it wrong |
|---|---|---|
| `key` | short slug; names every file for this object | must be unique, lowercase, no spaces |
| `display` | goes in the workbook filename | `Bills Approver Matrix - August 2026` |
| `sobject` | API name, used in the ObjectPermissions query | must match Salesforce exactly, e.g. `Credit_Check__c` |
| `report_id` | the 15/18-char report id | see below |
| `report_name` | the report's title **as displayed on the page** | this is the OCR marker — if it does not match what the page shows, every shot for this object fails verification |
| `approvers` | names pre-filled in the Approval tab | left blank for them to sign |

`report_name` is the one that bites. It must be what Salesforce renders at the top of
the report, which is often plural where the object is singular — the Invoice object's
report is titled "Invoices Approver Matrix".

**Finding the report id:** open the report in Salesforce; the URL contains
`/lightning/r/Report/<id>/view`. Or query it:

```sql
SELECT Id, Name, DeveloperName, FolderName FROM Report WHERE Name LIKE '%Approver Matrix%'
```

After editing, run the control. `verify_out.py` checks that the number of workbooks
matches the number of configured objects, so a typo surfaces immediately.

## Change who approves

Edit `approvers` for that object. The names are pre-filled in the Approval tab; the
date and Y/N columns are left empty for the approver to complete.

## A new permission set gains Modify All

**Nothing to do.** Permission sets are discovered at run time: the ObjectPermissions
result is read out of the page, and every row without a profile name is treated as a
real permission set and gets its own assignment query, screenshot and workbook section.

This is deliberate — the previous version required editing three files in sync, and
missing one would silently drop a permission set from the evidence.

## The report's columns change

Nothing to do. The Results tab uses the CSV export's own header row, so whatever
columns the report has is what appears.

## Move to a different org or sandbox

Update `org` in `config.json` (`lightning_host`, `my_host`, `setup_host`) and the
`custom_setting` identifiers, which are org-specific.

To find the custom setting identifiers in the new org:

- **object id** (for `viewCustomSettings`): Setup → Custom Settings → click the setting;
  the URL contains `id=01I...`
- **key prefix** (for `listCustomSettingsData`): the first three characters of any
  record id of that custom setting, e.g. `a1X`

These two are **not interchangeable**. Passing the object id to the list page renders
"Invalid Custom Setting id" on an otherwise normal Setup page — which is why
`read_evidence.py` explicitly checks for the word "Invalid".

## Loosen or tighten the timing check

`limits.max_screenshot_export_gap_seconds` (default 180) is the maximum allowed between
a report's screenshot and its CSV export. In practice the gap is 4–5 seconds; the limit
exists to catch a run that stalled badly. Raising it much weakens the control — the
whole point is that the screenshot evidences the same population as the data.

---

## If you do need to touch the code

| you want to change | file |
|---|---|
| what gets screenshotted, in what order | `scripts/capture_all.sh` |
| how a screenshot is verified | `scripts/shot.sh` (OCR marker check) |
| which numbers are read off the images | `scripts/read_evidence.py` |
| workbook layout, tabs, formatting | `scripts/build.py` |
| final sanity checks on the workbooks | `scripts/verify_out.py` |

Keep the guarantee that makes this trustworthy: **never keep a screenshot that has not
been verified.** Producing no evidence is recoverable; producing wrong evidence that
reaches an auditor is not.
