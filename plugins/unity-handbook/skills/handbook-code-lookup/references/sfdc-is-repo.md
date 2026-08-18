# The SFDC-IS repository

Unity's Salesforce metadata repository: **`unity/SFDC-IS`** on Unity's internal GitHub Enterprise at `github.cds.internal.unity3d.com`.

This is the **secondary** source. The org holds what is deployed and running; the repo holds history, review context, and work not yet deployed. Read the org first.

---

## Reachability — read this before promising anything

`github.cds.internal.unity3d.com` is an **internal host**. It is not reachable from every environment Claude Code runs in.

Confirmed on 17 August 2026 from a managed remote (Claude Code on the web) session:

```
curl https://github.cds.internal.unity3d.com/unity/SFDC-IS
→ CONNECT tunnel failed, response 403   (egress policy denial)
```

That is an organisation network-policy denial, not a transient failure and not an auth problem — retrying, or trying a different URL for the same host, will not help.

**Where it does work:**

| Environment | Repo access | Notes |
|---|---|---|
| Claude Code on your own machine, on the Unity network / VPN | ✅ | The normal case. Clone or point at an existing checkout. |
| Claude Code on the web / a managed remote session | ❌ by default | Internal hosts are blocked by the environment's egress policy. An admin can allow the host when creating the environment. |
| The GitHub MCP server in this session | ❌ | It is scoped to `github.com` repositories, not Unity's GitHub Enterprise. |

**So the rule for this skill:** if the repo is not reachable, say so plainly in one line, answer from the org, and name what specifically is missing as a result (history, review context, flow internals). Never stall on it, and never substitute a guess for repo content.

---

## Using a local checkout

When the repo is available, prefer a **local clone** over any network fetch — it is faster, works offline, and gives full `git log` / `git blame`.

Resolution order for the checkout path:

1. `$SFDC_IS_PATH`, if set.
2. A path the user names in the conversation.
3. Common locations — `~/SFDC-IS`, `~/dev/SFDC-IS`, `~/unity/SFDC-IS`, `~/src/SFDC-IS`.
4. Otherwise **ask** for the path. Do not guess, and do not clone a multi-gigabyte metadata repo without being asked.

Verify you have the right thing before reading — a Salesforce metadata repo has a recognisable shape:

```
force-app/main/default/
├── classes/          # ApexClass — .cls + .cls-meta.xml
├── triggers/         # ApexTrigger
├── flows/            # Flow XML  ← the approval/branch logic the org won't expose
├── objects/          # per-object: fields/, validationRules/, recordTypes/, listViews/
├── lwc/  aura/       # components
├── permissionsets/   # PermissionSet
├── workflows/        # email alerts, field updates
└── email/            # templates
```

Older repos use `src/` with the same subdirectories instead of `force-app/main/default/`. Check both.

---

## What the repo adds that the org cannot

| Question | How |
|---|---|
| Who changed this threshold, when, and why? | `git log -p --follow force-app/main/default/classes/<Class>.cls` |
| Who last touched this line? | `git blame` on the file |
| What was the review discussion? | The pull request that introduced the commit |
| **What are the actual branch conditions and thresholds inside a flow?** | `force-app/main/default/flows/<FlowApiName>.flow-meta.xml` |
| Validation rule messages | `objects/<Object>/validationRules/*.validationRule-meta.xml` |
| Email alert recipients | `workflows/<Object>.workflow-meta.xml` |
| Is deployed code behind the repo? | Compare the repo file against `ApexClass.Body` from the org |

**The flow XML row is the important one.** The handbook's approval thresholds, approver-chain step logic and skip conditions are its most business-critical content, and `handbook-refresh` currently has to report all of it as `NEEDS MANUAL CHECK` because `FlowDefinitionView` exposes only the header. Flow XML in this repo would make that block **machine-checkable** — the single biggest available upgrade to handbook assurance.

---

## Hard rules

- **Read-only.** Never commit, push, branch or open a PR in `SFDC-IS` from this skill. It is a production metadata repository; changes there deploy to Salesforce.
- **Never treat the repo as authoritative over the org** for "what is running now". Deployed code wins; the repo can be ahead (unmerged) or behind (production hotfix).
- **Say which you read.** Every answer states whether it came from the org, the repo, or both — and when they disagree, report the disagreement rather than reconciling it silently.
- **Do not paste large amounts of proprietary source** into a response. Quote the specific lines that answer the question and cite the file path.

---

## Enabling repo access for remote sessions

If the team wants this working in Claude Code on the web rather than only on local machines, the internal host has to be allowed by the environment's network policy — that is set when the environment is created, by whoever administers it, and is documented at https://code.claude.com/docs/en/claude-code-on-the-web.

Until then: **the org path covers most questions** (deployed Apex, triggers, schedules), and the repo path is for history and flow internals, run from a local session.
