# Definition tab approval rules — parsing and exception logic

The `Definition` tab has two tables. Both live in the master tracking workbook
(not in a bare per-quarter query export) — pull it from the master sheet or a
recent quarter's full workbook copy, not from a raw `Sheet1` export.

## Table 1: general rule (rows near the top)

| Column | Condition | Filter |
|---|---|---|
| `Assignee.IsActive` | EQUALS | `TRUE` |
| `Profile.PermissionsIsSsoEnabled` | EQUALS | `TRUE` (comment: "Explain If FALSE") |
| `Rest of Permissions` | EQUALS | `FALSE` (comment: "Explain if TRUE") |

Plus two free-text notes: "Review and Approve all Red Cells" and **"System
Admin should have all permissions"** — this last one is a blanket rule: treat
`System Administrator` as an automatically-approved profile for every single
permission column, even when it's not explicitly listed in that column's
approved-profiles cell below.

## Table 2: "Explenations" (per-permission approved-profile lists)

Header: `Permission name | Reason | Exclude Profiles approved: | Apprvoal |
Action Needed | Status`.

- `Permission name` cells sometimes list **multiple column names joined by
  `\n`** — one row's rule applies to all of them (e.g. one row covers
  `PermissionsManageSessionPermissionSets`, `PermissionsManageTwoFactor`, and
  `PermissionsManageExternalConnections` together). Split on `\n` to get each
  individual column name.
- `Exclude Profiles approved:` is also `\n`-joined — split, strip, drop blanks.
  Special values:
  - `All` → every profile is approved for this permission; never flag it.
  - `N/A` → no profile is explicitly pre-approved *other than* the blanket
    System Administrator rule above.
  - **Watch for parenthetical descriptions appended to a profile name**, e.g.
    `Sales Insights Integration User (For Sales integration)` — Salesforce's
    actual `Profile.Name` field on the row is just `Sales Insights
    Integration User`, no parenthetical. Match on prefix (approved entry
    starts with the actual profile name, followed by end-of-string, a space,
    or an open paren), not exact string equality, or every such profile will
    show up as a false-positive exception every quarter.

## Exception logic (what actually needs review)

For every row in the quarter's data, for every one of the 40 permission
columns (J:AW):

1. **`Profile.PermissionsIsSsoEnabled`** is the one reversed case: the
   *default expectation* is `TRUE`. A row is a genuine exception only if the
   value is `FALSE` **and** the row's `Profile.Name` is not in that column's
   approved list (that list holds the profiles who are *expected* to have SSO
   disabled, e.g. integration/system accounts).
2. **Every other permission column**: default expectation is `FALSE`. A row
   is a genuine exception only if the value is `TRUE` **and** `Profile.Name`
   is not in that column's approved list and is not `System Administrator`.
3. A permission column whose approved list is `All` is never flagged.

Excluding approved-profile combinations from the flagged set is the whole
point of this pass — it turns "every permission grant" into "only the grants
that don't have a pre-approved reason," which is what a SOX reviewer actually
needs to look at.

## Output shape

Produce a workbook with:
- An `Exceptions` sheet: one row per (User, permission-column) exception
  found, with columns `Id, Name, Profile.Name, Permission, Value` — this is
  the literal "red cells" list, already filtered to exclude approved profiles.
- A copy of the `Definition` tab (both tables), so the workbook is
  self-contained and a reviewer can see the rules used without needing the
  original master sheet open side by side.
