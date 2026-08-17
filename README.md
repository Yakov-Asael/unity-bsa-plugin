![Unity BSA Marketplace banner](./assets/banner.png)

# Unity BSA Marketplace

A Claude Code plugin marketplace hosting **`unity-bsa`** — the Unity Business Systems team's Salesforce delivery toolkit. One install gives your team a set of focused skills that turn the BSA workflow (flows, technical design, mockups, comms, decks, QA, project planning) into repeatable, standards-enforcing actions.

## What's inside

| Plugin | Description |
| --- | --- |
| [`unity-bsa`](./plugins/unity-bsa) | Salesforce BSA toolkit — 8 skills covering the full delivery lifecycle, each enforcing Unity's real standards. |
| [`unity-sox`](./plugins/unity-sox) | SOX compliance toolkit — quarterly access reviews (User/Profile + PermissionSetAssignment) and Setup Audit Trail change-management review. Script-driven and audit-ready. |
| [`unity-handbook`](./plugins/unity-handbook) | BSA Process Handbook — answers questions about the twelve documented Salesforce processes, and verifies itself against the live org so it stays current. |

## Install

This marketplace is a git repository. How you consume it depends on where your team runs Claude:

### Claude app / Cowork (upload)
The team runs in the Claude desktop/web app. Install the plugin file directly:
1. **Customize → Skills → Create plugin → Upload plugin**
2. Select `plugins/unity-bsa` packaged as a `.plugin` file (see the plugin README).

### Claude Code CLI or Cowork "Add marketplace" (recommended — supports one-click updates)
```
/plugin marketplace add Yakov-Asael/unity-bsa-marketplace
/plugin install unity-bsa
/plugin install unity-sox
/plugin install unity-handbook
```
This repo is **public**, so the marketplace path works without any auth — and you get updates with a single **Sync** (no uninstall/re-upload).

## Updating

- **Marketplace (recommended):** hit **Sync** on the marketplace, then reinstall/refresh — pulls the latest version automatically.
- **Upload:** uninstall and re-upload the latest `.plugin`.
- **Team-wide, managed:** publish via **Organization plugins** (your Cowork org admin) for centrally-maintained updates.

## Author

Unity Business Systems team.
