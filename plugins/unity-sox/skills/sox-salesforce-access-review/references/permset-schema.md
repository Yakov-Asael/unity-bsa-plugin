# Test 2 (ProfilePermissionSets) — column schema

Source object: `PermissionSetAssignment`, not `User`/`Profile` like Test 1.
Confirmed against the real Q1 workbook (`ProfilePermissionSets- Q1 review
2026`), not assumed from Test 1's shape — the tab names and columns differ.

**Tab names** (exact):
- `Query to Review new` — the SOQL query text (note: different name than Test
  1's `Query` tab — don't assume they match)
- `IPE` — empty/placeholder, ignore
- `Raw Data` — the actual pulled data (note the space — different from Test
  1's `RawData`)
- `Definition` — same two-table shape as Test 1 (general rule + Explanations),
  but the approved-profile lists mix Profile names, Permission Set names, and
  occasionally named individuals — see references/permset-definition-rules.md
- `To Review` — no leading space (Test 1's version has a leading space in the
  tab name — don't assume they match)

**Columns** (41 total, `A` through `AO`):

| Col | Header |
|---|---|
| A | `_` (blank/unused) |
| B | `Assignee` (literal `[User]` marker, not real data) |
| C | `Assignee.Username` |
| D | `Assignee.IsActive` |
| E | `ExpirationDate` |
| F | `IsActive` (the PermissionSetAssignment record's own active flag) |
| G | `PermissionSet` (literal `[PermissionSet]` marker, not real data) |
| H | `PermissionSet.Name` |
| I | `PermissionSet.Id` |
| J–AO | `PermissionSet.Permissions*` booleans (39 columns — fewer than Test
  1's 40; this object doesn't have `PermissionsManageLoginAccessPolicies`,
  `PermissionsCreateMultiforce`, `PermissionsInstallMultiforce`,
  `PermissionsPublishMultiforce`, `PermissionsImportCustomObjects`,
  `PermissionsManageCertificates`, or `PermissionsManageDataIntegrations`) |

**Key column(s)**: there is no single unique record Id exposed in this
export. Match rows across quarters on the **composite key**
`(Assignee.Username, PermissionSet.Name)` — one user can hold multiple
permission set assignments, so neither field alone is unique.

**Diff/exception range**: `J:AO` (`PermissionSet.PermissionsIsSsoEnabled`
through `PermissionSet.PermissionsScheduleJob`), same default-expectation
rule as Test 1 (`IsSsoEnabled` should be `TRUE`, everything else should be
`FALSE`).

## The profile-mirror artifact — read this before building anything else

The overwhelming majority of rows in this export are **not** genuine custom
Permission Set grants. Salesforce auto-creates a hidden Permission Set for
every Profile, named `X<ProfileId>` (e.g. `X00e0N000000JEu1QAG`, where
`00e0N000000JEu1QAG` is a real `Profile.Id` from Test 1's data) — every user's
`PermissionSetAssignment` to their own profile shows up as a row here. In the
real Q1 data this was ~1,232 of ~1,280 rows (96%).

Only rows where `PermissionSet.Name` does **not** match the `X<18-char-ID>`
pattern are genuine, explicitly-assigned custom Permission Sets (e.g.
`GenieAdmin`, `Integration_Permissions_for_SSO`, `sfdc_einsteinagent`,
`ServiceCatalogBuilder`). There were only ~13 of these in Q1.

**Handling rule** (per user decision): do not discard the profile-mirror rows.
Map `X<ProfileId>` back to its real profile name (cross-reference against
Test 1's `RawData`/`Raw Data` — same `Profile.Id` values appear in both
tests' data) and evaluate that row against Test 2's own Definition-tab
approved lists using the resolved profile name, same as any other row. Keep
the resolved name alongside the raw `X<ProfileId>` value in any output so a
reviewer can see both.

**Only trust the resolution if the extracted Id is a confirmed member of
Test 1's Profile.Id list.** Some `PermissionSet.Name` values are ID-shaped
(`X` + 15 chars, sometimes with a mangled/suffixed tail like
`X00ex00000018ozT_128_09_43_34_1`) but don't correspond to any real
`Profile.Id` — treating these as a confident profile-mirror match produces
mass false-positive exceptions (this happened during testing: one such Id,
used by 15 people who all looked like admins, generated 420 false
exceptions before the bug was caught). If the Id doesn't resolve, route it
to manual review instead of a confident exception or a confident approval.

**Known confirmed identity aliases** (told to us directly by the user,
not inferable from the data): `X00ex00000018ozT_128_09_43_34_1` is the
`System Administrator Custom` permission set — a real, distinct permission
set, not a plain profile-mirror. Per explicit instruction, treat it as
approved **only** on the columns where the Definition tab names
`System Administrator Custom` exactly (the SSO column, at last check) — do
**not** let it inherit approval anywhere plain `System Administrator` is
listed via loose/substring matching, since that would silently over-approve
it elsewhere. If a future quarter surfaces another unresolvable ID-shaped
name, ask the user what it is rather than guessing — don't assume it's
automatically a System Administrator variant.
