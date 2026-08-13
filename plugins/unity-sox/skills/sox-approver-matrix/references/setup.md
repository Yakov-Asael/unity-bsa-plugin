# Setup — what you need before running the control

Run `scripts/setup.sh` then `scripts/preflight.sh` first. Preflight tells you exactly
what is missing. This file explains *why* each item is needed, which matters when
something looks granted but does not work.

macOS only. The control drives a real Chrome browser and takes real screenshots,
because the screenshot — with the menu-bar clock in it — is the audit evidence.

---

## 1. Screen Recording

**System Settings → Privacy & Security → Screen Recording → enable Claude**
(or whichever app runs the scripts — Terminal, iTerm, VS Code).

**Then quit that app and reopen it.** macOS keeps reporting the old state until the
process restarts, so it will look granted and still fail.

Without it, `screencapture` fails and no evidence can be produced at all.

## 2. Accessibility

**System Settings → Privacy & Security → Accessibility → enable the same app.**
Again, **quit and reopen** afterwards.

This allows keystrokes. The control needs Ctrl+Enter to run each Salesforce Inspector
query.

Note that macOS treats keystrokes and mouse clicks as separate privileges here.
Keystrokes work with this granted; **synthetic mouse clicks stay blocked** (`-25211`),
which is why the Filters tab is opened with JavaScript instead of a click.

## 3. Chrome: Allow JavaScript from Apple Events

**Chrome's macOS menu bar at the top of the screen → View → Developer →
Allow JavaScript from Apple Events**

This is the one people cannot find. It is **not** in the ⋮ menu inside the browser
window — that menu has no Developer entry. Use the menu bar at the very top of the
screen, with Chrome focused. Developer is near the bottom of the View menu.

It is used for two things:

- opening the report builder's **Filters** tab (the builder opens on Outline, and the
  tab needs a click that macOS will not let us synthesise)
- reading the **Modify All** result tables out of the Inspector page, so the workbook
  data and the screenshot come from the same query run

To turn it off later, same menu, click again.

*Security note:* this setting lets any AppleScript on the machine run JavaScript in
Chrome pages. It is local, does not sync, and is reversible in two clicks — but it is a
real change, so make it deliberately.

## 4. Google Chrome, signed in to production

Chrome must be running and signed in to **Salesforce production**. The control uses the
browser's existing session; it never handles credentials.

If the session has expired, the run captures login pages instead of reports. Preflight
warns when it cannot see a Salesforce tab, but it cannot tell whether the session is
still valid — check by opening a report yourself first.

## 5. Salesforce Inspector Reloaded

The Chrome extension used for the Modify All evidence
(`hpijlohoihegkfehhibggnkbjhoemldh`). Install from the Chrome Web Store if preflight
cannot find it.

## 6. Xcode Command Line Tools

`xcode-select --install`

Needed once, to compile the small Swift helper that does OCR through Apple's Vision
framework. `setup.sh` builds it.

---

## While the control runs

**Leave the machine completely alone for about ten minutes.** No keyboard, no mouse, no
Chrome.

**Park the mouse pointer in a corner of the screen.** A cursor resting over the tab
strip pops a tooltip that covers the URL bar in the evidence.

**Do not connect or disconnect a monitor mid-run.** Screenshots come from whichever
display Chrome is on, and hot-plugging moves windows between displays.

**Close the output workbooks in Excel** before re-running.

The run drives its own Chrome window and never navigates your tabs. But it captures
whole screens, so whatever is in front ends up in the evidence. Every screenshot is
OCR-checked before it is kept, so a stray window causes a *failed* shot rather than a
bad one — but that still costs you the run.

---

## Environment quirks worth knowing

Each of these caused a real, hard-to-diagnose failure:

- **`screencapture` silently refuses any filename that begins with a dot.** It exits 0
  and writes nothing. A probe writing to `/tmp/.probe.png` failed every time and looked
  like intermittent flakiness.
- **The Salesforce REST API rejects the browser session** (`INVALID_SESSION_ID`), so
  report data comes from the classic CSV export URL. The `isdtp=nv` parameter is what
  prevents Lightning from redirecting and swallowing the export.
- **The report builder is inside a same-origin iframe and uses shadow DOM.** A plain
  `document.querySelectorAll` finds nothing; the opener walks frames and shadow roots.
- **The two Custom Settings pages take different identifiers.**
  `viewCustomSettings` wants the object id, `listCustomSettingsData` wants the key
  prefix. The wrong one renders "Invalid Custom Setting id" on a normal-looking page.
- **OCR is not character-perfect on UI text** — "Total Records" has come back as
  "Totel Records" — so label matching is deliberately fuzzy.
