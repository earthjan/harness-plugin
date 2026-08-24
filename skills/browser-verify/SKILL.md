---
name: browser-verify
description: Verify ListaNatin mobile UI in a real browser using agent-browser. Use when reviewing, dogfooding, or QA-ing any screen in this repo — verifying layouts/states with screenshots, logging into the app as a dev user, or checking the dev showcase. Wraps the external `agent-browser` skill (generic tool) with this repo's phone-viewport and dev-auth invariants. NOTE: this skill is a project-specific wrapper — its dev-server URL, viewport, and dev-auth accounts belong to lista-natin. Before reusing it on a new project, swap those specifics for that project's own (see Applicability below).
---

# Browser Verification (ListaNatin)

This is the project's wrapper around the global `agent-browser` skill. Use `agent-browser` for the actual
commands (it's the generic, version-matched tool — always load its core workflow first with
`agent-browser skills get core`); this skill adds the **project invariants** that `agent-browser` cannot know.

## Applicability — this skill is a project-specific wrapper

Everything below (the phone viewport size, the dev-server URLs, the `/dev-showcase` route, and the
`admin@dev.test`/`participant@dev.test` accounts) is **lista-natin's own configuration**, shown here as a
worked example of what a project needs to fill in when wrapping `agent-browser` for itself — not a
universal default. Before using this skill (or copying it) in a different project, replace:

- the dev-server base URL and port (lista-natin's is Expo on `http://localhost:8081`),
- the target viewport(s) (lista-natin targets Samsung Galaxy A51 at 412×914, checked narrow against a
  344×882 Z Fold cover screen — a non-mobile project may need a completely different viewport strategy,
  or none at all),
- any project-specific routes (lista-natin's `/dev-showcase`),
- and the dev-auth accounts/mechanism (lista-natin's `EXPO_PUBLIC_ENABLE_DEV_EMAIL_AUTH` + two seeded
  Firebase Auth accounts) —

with whatever the current project actually documents for local dev verification. Do not silently apply
lista-natin's values to a different project's UI.

## Non-negotiable: phone viewport — at TWO widths

This repo targets phones (Samsung Galaxy A51, **412 × 914** logical px). Every layout judgment is made at
phone width. A desktop-width screenshot will mask column/row collapse bugs and make broken layouts *look
fixed.

A single width is not enough either: a layout that only gets judged at 412dp can hide a fixed-width
trailing element forcing truncation, or a single flex row with no reflow strategy that wraps mid-word once
space tightens (see `docs/agent-learning-logs.md` 2026-08-21, finding #3). **A layout is not done until it
has been screenshotted at both the target width and a meaningfully narrower one.**

The narrow width is the **Samsung Galaxy Z Fold cover screen** — the slimmest mainstream phone screen on
the market, **344 × 882** logical px — not an approximation. If a layout survives this, it survives
anything narrower we're likely to see.

**Always, in this order, before assessing any layout:**

```bash
# 1. Open the browser session (browser persists across commands via a daemon)
agent-browser open http://localhost:8083/<screen>

# 2. Set the viewport to a phone — right after open, BEFORE navigating or screenshotting
agent-browser set viewport 412 914

# 3. Navigate + screenshot at target width
agent-browser screenshot /path/to/screenshot-412.png

# 4. Re-check at the Z Fold cover-screen width — narrow enough to expose reflow bugs
agent-browser set viewport 344 882
agent-browser screenshot /path/to/screenshot-344.png
```

> ⚠️ **Only `agent-browser set viewport <w> <h>` works.** The `--viewport-width 412 --viewport-height 914`
> and `open --viewport 412x914` flags do NOT work, and there is no `viewport` subcommand. After each `set
> viewport`, always screenshot and confirm the page is actually that width before judging a layout.

**Do not present a layout as done from the 412dp screenshot alone.** Before calling any list-row-shaped
element (avatar + name + tag + amount, etc.) finished, confirm at 344dp that: the name never
wraps mid-word or gets clipped, and any secondary content (date/status, then decorative elements like a
rank badge) is what degrades first — per DESIGN.md §24 "No Scrolling" and §4's reflow rule.

## Interaction smoke check — every interactive element, not just its screenshot

A screenshot proves an element *looks* right; it proves nothing about whether it *does* anything.
`ContributionGridSection`'s row/chip tap shipped fully styled and completely dead — the callback was
declared in the props type but never wired to `Pressable.onPress` — and it survived a full
screenshot-based review because nothing ever clicked it (see `docs/tickets/103/0001_iteration`).

**Before calling any screen done, tap every element that looks interactive** (row, chip, button,
disclosure control, tab/segment) and confirm an observable effect — navigation fires, a sheet opens,
state visibly changes on the next screenshot. An element that looks tappable (icon, chevron, colored
chip, list row) but produces no effect is a bug, not a nitpick, even if its screenshot is pixel-perfect.

```bash
agent-browser click "<selector or text>"
agent-browser screenshot /path/to/after-click.png   # compare against before-click — something must differ
```

State the specific claim, per DESIGN.md §24 evidence discipline: "tapping the member row navigates to
/HulogDetailSheet — confirmed, sheet visible in after-click.png" — not "tap targets present."

## Mock-parity check — when a wireframe/mock file exists

If this delivery has a reference mock (`wireframe.html`, `hifi.html`, or similar named in `PLAN.md`),
a visual "looks similar" pass is not enough — the wireframe encodes specific elements (icons, gaps,
badges, tap targets) that are easy to silently drop during implementation (see
`docs/tickets/103/0001_iteration`/`0002_iteration`: a missing status-chip icon, a collapsed
`marginBottom: 0` gap between cards, and an overflowing member row all shipped past screenshot review
because nothing checked the mock element-by-element).

Screenshot the mock and the live implementation at the same viewport(s), then walk the **Mock Element
Inventory** from `PLAN.md` (see `ship-ui` Phase 1) top to bottom — for each entry, state whether it is
present, wired, and positioned per the mock, with the screenshot or measurement that proves it. Do not
summarize as "matches the mock" — that is the same unfalsifiable claim `docs/agent-learning-logs.md`
(2026-08-21) already flagged as insufficient for geometry; it is equally insufficient for completeness.

## Dev auth (role testing)

Log in with the local dev accounts (enabled via `EXPO_PUBLIC_ENABLE_DEV_EMAIL_AUTH=true` in `.env.local`,
never committed):

- Admin: `admin@dev.test` / `password`
- Participant: `participant@dev.test` / `password`

Role inference: admin = user uid matches `sessions.adminId`; participant = has a `sessionParticipants` record.

## Local base URLs

- Expo dev server: `http://localhost:8081` (use the `/dev-showcase` route for the showcase)
- Render/deploy previews: use the port from the relevant plan doc (e.g. `http://localhost:8083/...`)

## Verification loop

1. Open the screen at the base URL.
2. `set viewport 412 914`; screenshot and confirm phone width.
3. Exercise the state(s) under review (navigate, login as admin/participant as needed).
4. Screenshot each state at phone width before judging.
5. `set viewport 344 882`; re-screenshot each state under review before calling any of them done —
   catches truncation and mid-word wrap bugs the 412dp width hides.
6. Tap every interactive-looking element and confirm an observable effect (see Interaction smoke
   check above) — a dead tap handler is invisible to screenshots alone.
7. If a wireframe/mock file exists for this delivery, walk the Mock Element Inventory from PLAN.md
   against the live screenshots (see Mock-parity check above) before calling the layout done.

For exploratory/QA work, prefer `agent-browser skills get dogfood` for the exploratory workflow.
