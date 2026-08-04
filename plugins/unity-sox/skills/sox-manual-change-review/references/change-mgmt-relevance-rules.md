# Test 3 — Relevance classification: whitelist approach

## Why not Type or keywords

Two simpler approaches were tested against 2,203 real Q1 labels
(`Data Filtered` tab, `Relevant` column) before building anything, and both
failed badly:

1. **Type-based** (`Development`/`Various Set up`/`Customization` = Relevant):
   10.2% accuracy. Nearly everything in `Data Filtered` has one of these
   three Types (the data is pre-scoped to them by the SOQL query itself), so
   this rule predicted "Relevant" for almost every row while only 224/2203
   actually are.
2. **Generic financial keywords** (`deal`, `credit`, `dispute`, `invoice`,
   `bill`, `finance`, `payment`, `revenue` in the `Action` text): 46.8%
   precision, 88.8% recall. Same object name appears on both sides depending
   on the *kind* of change — `Changed Bill page layout` is Not Relevant,
   `Changed label of custom field from Deal Reviewed By Finance to Revenue
   Accounting Approval` is also Not Relevant, despite matching keywords.
   Cosmetic edits (page layouts, picklist value additions, custom field
   labels, formula fields) are reliably Not Relevant even on financial
   objects — don't treat keyword presence as sufficient on its own.

## What actually works: named-flow/process whitelist

Relevance tracks specific, recurring, identifiable Flow/Approval
Process/Validation Rule names — not generic language patterns. Tested at
91.9% precision / 86.2% recall against the same 2,203 rows.

### Building the whitelist

1. Exclude cosmetic-pattern actions before attempting to extract a name at
   all — these are reliably Not Relevant regardless of the object touched:
   - contains `page layout`
   - contains `picklist`
   - contains `changed label of custom field`
   - contains `custom formula field`
2. From the remaining rows, extract the flow/process name: prefer the
   quoted string in the Action text (e.g. `Activated flow version #10
   "Create Opportunity Deal Ads" for flow with Unique Name "..."` → `Create
   Opportunity Deal Ads`); fall back to text after `Approval Process:` if no
   quoted name is present.
3. The whitelist is the set of these extracted names from rows the user (or
   a prior quarter) has confirmed `Relevant`.

### Classifying a new quarter's rows

1. Cosmetic-pattern actions (see list above) → always `Manual Review` (not a
   confident Not Relevant — a human should still glance at these, just at
   lower priority; don't silently auto-clear them).
2. Extract the name (same logic as above). If it matches an entry in the
   whitelist → `Confident Relevant`.
3. Everything else (unrecognized name, or no name extractable, but not
   cosmetic) → `Manual Review`. This is the correct behavior for a
   brand-new financial process that hasn't been confirmed yet — it should
   surface for a human decision, not get silently dropped or silently
   auto-approved.
4. There is deliberately **no "Confident Not Relevant" tier** — the tested
   rules never produced a reliable enough signal to auto-clear something as
   safe. Everything is either flagged as a known Relevant pattern or sent to
   a human. This matches the user's own instruction: "if you are not sure,
   tag them as manual review."

### Whitelist maintenance — this is a living list, not a one-time build

The whitelist must grow over time. Each quarter:
1. Start from the whitelist as it stood at the end of the previous quarter
   (persist it — don't rebuild from scratch each time from only the most
   recent quarter's confirmed-relevant rows, or you'll lose older recurring
   processes that didn't happen to recur this particular quarter).
2. After the user reviews this quarter's `Manual Review` bucket and confirms
   any of those rows as genuinely relevant, add their extracted names to the
   whitelist for next quarter. Ask the user explicitly which `Manual Review`
   names (if any) should be promoted — don't decide this automatically.
3. Store the current whitelist in the skill's own files (see
   `scripts/change_mgmt_classify.py`) so each quarter starts from the latest
   confirmed set — it should NOT be hardcoded to only the 36 names found
   in the original Q1 analysis; update it as the user confirms new ones.
