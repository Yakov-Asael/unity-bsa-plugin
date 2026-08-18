# Contributing to the Unity BSA Marketplace

Welcome. This repo hosts the team's plugins — **`unity-bsa`**, **`unity-sox`** and **`unity-handbook`** — and their skills. Anyone on the team can build new skills (or improve existing ones) — but everything ships through a reviewed flow, and **only the maintainer releases to production**.

> New here? Read the **[Skill & Plugin Creator Guide](./docs/skill-creator-guide.md)** first — it explains what a good skill/plugin looks like and the mandatory build process.

## Roles & release policy

| Role | Who | Can do |
| --- | --- | --- |
| **Maintainer** | @Yakov-Asael | Merge to `main`, bump the version, release to production. |
| **Contributor** | Collaborators (Write) | Build on branches, open PRs into `develop`, review each other. |

**Release is the maintainer's alone.** `main` is protected: every change needs the maintainer's code-owner approval and a green CI check. Contributors never merge to `main`.

## Branches

- **`main`** — production. The marketplace serves this branch. Protected; maintainer-only.
- **`develop`** — integration / team space. PRs land here for review.
- **`feature/<skill-name>`** — your working branch, one per skill/change.

## The flow (per new skill)

1. **Open a "New skill" issue** — fill the brief. A one-line request is not enough (the form won't let you). This is the plan we review against.
2. **Branch** `feature/<skill-name>` off `develop`.
3. **Build** using the scaffold in [`_template/skill/`](./_template/skill) and the [Creator Guide](./docs/skill-creator-guide.md).
4. **Test** the skill on a **real Unity example** and capture the result in your PR.
5. **Run the checks locally:** `python3 scripts/validate_plugin.py`.
6. **Open a PR into `develop`** — fill the PR template. A teammate reviews (mentoring happens here); a maintainer merges.
7. **Release:** the maintainer opens `develop → main`, bumps the version, and merges = production.

## The bar (non-negotiable)

- **Brief first, plan before building.** No skill starts from a one-liner — start from the issue brief, then design, then build.
- **Every skill has:** a `SKILL.md` (frontmatter `name` = folder, trigger-rich `description`), a `references/` for detail, a **`README.md`**, and an **`assets/banner.png`**.
- **Update the plugin README.** When you add a skill, add its row to the plugin's `README.md` skills table. **CI fails if you don't.**
- **Follow Unity conventions:** respond in English; plan → self-review → end with a Next Step; the palette (`#2196F3` / `#0F61A3` / `#141514`); *fit the use case, don't force the template*; respect skill **boundaries** (don't overlap another skill's job).
- **No `WIP` markers** on a skill you're shipping as active.

## Keeping documented content current

Most skills here encode a **standard** (a template, a ruleset, a review bar) — those change slowly and deliberately. `unity-handbook` is different: it documents **the current state of twelve production Salesforce processes**, so it decays every time someone deploys, silently, while its answers stay confident.

**If your change touches Dispute, Handover, Connect 360, GDRC, Credit Check, Customer Community, Knowledge, CSAT, Deals, Pipeline Summary, GPS or Bills/Invoice Sync — update that process's reference file in the same PR.** Scheduled verification sweeps are a safety net for what this rule misses, not a replacement for it.

Full policy — ownership, cadence, source-of-truth precedence, and what "verified" is allowed to mean: **[Handbook Maintenance Policy](./docs/handbook-maintenance.md)**.

## Local checks

```bash
python3 scripts/validate_plugin.py     # manifests + skill completeness + README discipline
node scripts/make-banner.js <skill> "<Title>" "<tagline>" <icon>   # generate an on-brand banner
```

## Versioning

Semantic versioning in `plugins/unity-bsa/.claude-plugin/plugin.json`. **The maintainer bumps the version at release** — don't bump it in feature PRs.
