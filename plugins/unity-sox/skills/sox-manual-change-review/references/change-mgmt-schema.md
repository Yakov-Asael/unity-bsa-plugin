# Test 3 (Change Management Review) — schema and workflow

Source: Salesforce Setup Audit Trail (`SetupAuditTrail`), not `User`/`Profile`/
`PermissionSetAssignment` like Tests 1 and 2. Confirmed against the real
workbook (`Grow SFDC-IS Change Review - 2026 Q1- SOX Compliance`).

**Tabs** (exact names):
- `Query to Review new` — SOQL query text, leave untouched each quarter
- `IPE` — user pastes screenshot manually, not handled by this skill
- `Users to Exclude` — single column (`User name`) of usernames/integration
  account names to filter out entirely (~24 rows: `ba-devops@unity3d.com`,
  `oktauser@unity3d.com`, `Jira Cloud for Salesforce`, etc.)
- `Section -> Type` — 112-row lookup mapping the audit log's `Section` value
  to one of 7 categories: `Development`, `Various Set up`, `Customization`,
  `Administration`, `Security and Sharing`, `User Management`, `System Custom
  Admin Actions`
- `Raw Data` — the full unfiltered SOQL export (56k+ rows in Q1) — columns
  `Date, Date(parsed), Month, Relevant for Q<N>, User, Source Namespace
  Prefix, Action, Section, Delegate User`
- `Only Q1` (rename per quarter, e.g. `Only Q2`) — Raw Data filtered to the
  target quarter via the month formula, plus `Exclude Users?` column added
- `Data Filtered` — `Only Q<N>` with excluded users removed, plus `Type` and
  `Relevant` columns computed
- `Q<N> Changes to Review` — only the `Relevant` rows, with manual audit
  columns (`Associated Ticket`, testing/approval sign-off, conclusion)

**Quarter filter formula**: `Month` column (1-12) feeds
`=IF(OR(C2=1,C2=2,C2=3),"Q1","Not Q1")` for Q1. Parameterize by quarter:
Q1 → months {1,2,3}, Q2 → {4,5,6}, Q3 → {7,8,9}, Q4 → {10,11,12}. Always ask
or infer which quarter is being run — don't hardcode Q1's month set.

**Important scoping fact**: `Raw Data` is already scoped by the original SOQL
query to only `Setup type = Development, Various Setups, and Customizations`
(per the workbook's own Definitions tab) — `Data Filtered` never contains
`Administration`/`Security and Sharing`/`User Management` rows in practice.
Don't design relevance logic assuming those categories need filtering out at
this stage; they're excluded upstream, before this skill ever sees the data.

**Performance note**: `Raw Data` runs 50,000+ rows and the workbook overall
is several MB.
1. Always load with `openpyxl.load_workbook(..., read_only=True,
   data_only=True)` — a normal (non-read-only) load of this file took over 4
   minutes and hit the tool timeout during testing; read_only mode loads the
   same data in ~5-8 seconds. This applies even when only reading a small tab
   (e.g. `Users to Exclude`) from the same large workbook — the slowness
   comes from parsing the whole file's styles/structure, not the specific
   sheet size.
2. **Never call `ws.append()` and then look the row back up** (via
   `ws[ws.max_row]` or `ws.cell(row=ws.max_row, ...)`) to style it — on a
   normal writable worksheet this is O(n) per lookup, making the whole loop
   O(n²). At 15,000 rows this went from instant to a 90-second+ hang.
   Instead, create and style each cell in the same call:
   `cell = ws.cell(row=i, column=j, value=v); cell.fill = fill` — this stays
   linear (195,000 cells styled in ~2 seconds during testing) because the
   `Cell` object is captured directly at creation, with no later re-lookup.

**Raw export format** (confirmed from a real Q2 export): the raw
`SetupAuditTrail` CSV export from Salesforce has only 6 columns — `Date,
User, Source Namespace Prefix, Action, Section, Delegate User` — none of the
pre-computed `Date(parsed)`/`Month`/`Relevant for Q<N>` columns that exist in
the `Raw Data` *tab* of the master workbook. `change_mgmt_classify.py` parses
this raw CSV directly (no pre-processing needed): the `Date` field is a
string like `02/07/2026 14:57:30 IDT` (`DD/MM/YYYY HH:MM:SS TZ` — note
day-before-month), which the script parses to derive the month. The CSV is
**not always valid UTF-8** — a real export failed UTF-8 decoding on an
accented character and needed a `latin-1` fallback; the script already
handles this, but don't assume future exports are clean UTF-8 either.

## Relevance classification — see references/change-mgmt-relevance-rules.md

Do not use a Type-based or generic-financial-keyword rule for the `Relevant`
column — both were tested against 2,203 real historical labels and performed
badly (10% and 47% precision respectively). Use the whitelist-based approach
documented in that file instead (91.9% precision, 86.2% recall when tested).
