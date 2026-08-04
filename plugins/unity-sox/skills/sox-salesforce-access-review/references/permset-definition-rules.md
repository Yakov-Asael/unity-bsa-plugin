# Test 2 (ProfilePermissionSets) — Definition tab & exception logic

Same two-table shape as Test 1 (see references/definition-rules.md for the
base parsing approach — reuse it), with these Test-2-specific differences.

## General rule table

Identical structure to Test 1:
- `Assignee.IsActive` EQUALS `TRUE`
- `Profile.PermissionsIsSsoEnabled` (i.e. the assigned Permission Set's SSO
  flag) EQUALS `TRUE`, "Explain If FALSE"
- `Rest of Permissions` EQUALS `FALSE`, "Explain if TRUE"
- "Review and Approve all Red Cells"

Note: no separate "System Admin should have all permissions" blanket line was
present verbatim in this Definition tab at last check — don't assume it
carries over from Test 1. Re-check the actual tab each time; if a blanket
System Administrator approval line isn't there, don't invent one.

## Explanations table — messier than Test 1's

The `Exclude Profiles approved:` column here mixes three different kinds of
entries in the same free-text list:
1. **Plain profile names** (e.g. `System Administrator`, `Integration`) —
   match these the same way as Test 1, including the parenthetical-suffix
   handling (e.g. `System Administrator (For integrations)` should match
   profile name `System Administrator`).
2. **Permission Set names** (e.g. `Permission set called- Integration
   Permissions for SSO`, `Data Cloud user`, `AI Permissions sets`,
   `GenieAdmin`) — match against the row's actual `PermissionSet.Name` (or
   its resolved label if it's a profile-mirror row), not the profile.
3. **Named individuals** (e.g. `Only visable to Noam Abutbul,Neta Ronen,
   Amir, Yakov, Dror Diamant (Admins incharge of tool)`, `siddharth
   Panicker- Approved`) — free text naming specific people, not a
   profile/permission-set pattern.

**Handling rule for named individuals** (per user decision): don't attempt to
match the `Assignee.Username` against these free-text names — identity
matching from unstructured text is unreliable for a compliance check. Instead,
whenever a permission column's approved list contains what looks like named
individuals (heuristic: contains a personal name pattern, "Only visable to",
or "- Approved" rather than a clean profile/permission-set token), **always
flag any row using that permission set for manual review**, regardless of who
the assignee is. Say so explicitly in the output ("flagged for manual
identity verification — approved list names specific individuals") rather
than silently treating it as approved or as a hard violation.

## Data-quality gotcha: inconsistent column-name prefixes

At last check, the Definition tab's row for the SSO permission was literally
named `Profile.PermissionsIsSsoEnabled` (copy-pasted from Test 1's Definition
tab) instead of `PermissionSet.PermissionsIsSsoEnabled` — the actual column
name in Test 2's data. Matched literally, this silently drops every SSO
approval rule (all SSO approvals looked unapproved, producing dozens of false
positives during testing). When parsing the Explanations table, register each
rule under **both** the `Profile.` and `PermissionSet.` prefixed forms of its
name, so a lookup by the real data column succeeds regardless of which prefix
the Definition tab happens to use that quarter. Don't assume this typo is
fixed in future quarters — keep the dual-registration as a permanent
safeguard, not a one-time patch.

## Matching order for a given row/column

1. Resolve the row's effective "identity" for approval-matching: if
   `PermissionSet.Name` matches `X<ProfileId>`, resolve to the real profile
   name (see references/permset-schema.md); otherwise use the literal
   `PermissionSet.Name`.
2. If the column's approved list contains a named-individual pattern, flag
   for manual review unconditionally (see above) — don't run the normal
   approve/deny check for that cell.
3. Otherwise, check whether the resolved identity (profile name or
   Permission Set name) matches any entry in the approved list (profile-name
   matching uses the same prefix/parenthetical logic as Test 1; permission-set
   matching is exact-string after stripping whitespace).
4. Apply the same default-expectation logic as Test 1: flag `IsSsoEnabled` if
   `FALSE` and unapproved; flag any other column if `TRUE` and unapproved.

## Output requirement: Definition-tab annotations

Beyond the `Exceptions` sheet (same shape as Test 1's), this test's output
must also produce **exact instructions for updating the live cloned Sheet's
`Definition` tab, column E ("Action Needed")** — since there's no tool to
write that cell directly. For every permission row that had at least one
exception this quarter, output a line like:

> `Definition!E<row>` (permission: `<name>`) → change from `No Action is
> Needed` to: `"Q<N> <year>: flagged — <Name> (<resolved identity>) has this
> permission TRUE via <PermissionSet.Name>, not on approved list. Needs
> review."`

List every such row explicitly in chat (or a short text file) so the user can
paste each one in manually — don't just say "several rows need updating"
without naming them.
