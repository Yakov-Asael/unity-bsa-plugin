# Tracking sheet column schema

This is the exact column layout of the `RawData` and `" To Review"` tabs, confirmed
against the user's real workbook (not just a text dump — verified with openpyxl).
Both tabs share this identical header row and column order. If a new quarter's
sheet doesn't match this schema (extra/missing/reordered columns), stop and flag
the mismatch to the user before comparing — don't silently adapt.

**Tab names** (exact, case- and space-sensitive):
- `Query` — the SOQL query text
- `IPE` — empty/placeholder tab, ignore it
- `RawData` — the actual pulled data, this is what gets diffed
- `Definition` — reference tables (see below)
- `" To Review"` — has a **leading space** in the tab name — this is what gets
  rebuilt and handed back to the user each quarter

| Col | Header |
|-----|--------|
| A | _ (blank/unused — artifact of the Salesforce export, ignore) |
| B | Id |
| C | Name |
| D | IsActive |
| E | Profile |
| F | Profile.Name |
| G | Profile.UserLicense |
| H | Profile.UserLicense.Name |
| I | Profile.Id |
| J | Profile.PermissionsIsSsoEnabled |
| K | Profile.PermissionsApiEnabled |
| L | Profile.PermissionsAssignPermissionSets |
| M | Profile.PermissionsAuthorApex |
| N | Profile.PermissionsCustomizeApplication |
| O | Profile.PermissionsManageCustomPermissions |
| P | Profile.PermissionsManageInternalUsers |
| Q | Profile.PermissionsManageIpAddresses |
| R | Profile.PermissionsManagePasswordPolicies |
| S | Profile.PermissionsManageProfilesPermissionsets |
| T | Profile.PermissionsManageReleaseUpdates |
| U | Profile.PermissionsManageRemoteAccess |
| V | Profile.PermissionsManageRoles |
| W | Profile.PermissionsManageSessionPermissionSets |
| X | Profile.PermissionsManageTwoFactor |
| Y | Profile.PermissionsManageUsers |
| Z | Profile.PermissionsModifyAllData |
| AA | Profile.PermissionsModifyMetadata |
| AB | Profile.PermissionsPrivacyDataAccess |
| AC | Profile.PermissionsManageInteraction |
| AD | Profile.PermissionsModifyDataClassification |
| AE | Profile.PermissionsDelegatedTwoFactor |
| AF | Profile.PermissionsImportCustomObjects |
| AG | Profile.PermissionsManageCertificates |
| AH | Profile.PermissionsManageDataIntegrations |
| AI | Profile.PermissionsManageHealthCheck |
| AJ | Profile.PermissionsManageLoginAccessPolicies |
| AK | Profile.PermissionsOutboundMigrationToolsUser |
| AL | Profile.PermissionsInboundMigrationToolsUser |
| AM | Profile.PermissionsCreateMultiforce |
| AN | Profile.PermissionsInstallMultiforce |
| AO | Profile.PermissionsPublishMultiforce |
| AP | Profile.PermissionsManageAuthProviders |
| AQ | Profile.PermissionsManageC360AConnections |
| AR | Profile.PermissionsManageCMS |
| AS | Profile.PermissionsManageExchangeConfig |
| AT | Profile.PermissionsManageExternalConnections |
| AU | Profile.PermissionsManageHubConnections |
| AV | Profile.PermissionsManageSandboxes |
| AW | Profile.PermissionsScheduleJob |

**Key column**: `Id` (column B) — this is the unique Salesforce User Id used to
match a person across quarters. Never match on `Name` (not unique/stable enough).

**Diff range**: `J:AW` — all `Profile.Permissions*` boolean columns, including
`Profile.PermissionsIsSsoEnabled` (column J). Columns A–I (identity/profile
assignment fields) are excluded from the diff by default, per the user's
explicit instruction.

## Definition tab (reference only, not diffed)

The `Definition` tab has two tables:
1. **Definition Column/Condition/Filter** — the rules used to build the original query
   (e.g. `Assignee.IsActive EQUALS TRUE`, `Rest of Permissions EQUALS FALSE` unless
   explained).
2. **Explanations table** — one row per permission column, with:
   - `Reason` — why that permission exists / is needed
   - `Exclude Profiles approved` — which Profiles are allowed to have this
     permission set to TRUE
   - `Action Needed` / `Status` — typically "No Action is Needed" / "N/A" for
     pre-approved combinations

When summarizing a flagged change to the user, cross-reference the permission
column against this Explanations table and note whether the Profile now holding
that permission is in the approved list — this is what tells the user whether a
flagged change is expected/benign or a real SOX exception worth escalating.
