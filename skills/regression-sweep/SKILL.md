---
name: regression-sweep
description: End-to-end regression verification across a set of tickets — builds a scenario catalog scaled to each ticket's complexity and blast radius, drives it through the running app via agent-browser one scenario at a time, fixes genuine regressions test-first, and produces a scored sign-off. Use at sprint end or before a release to confirm shipped tickets still work and nothing regressed.
argument-hint: "ticket IDs to sweep, or omit to auto-scope to everything shipped since the last sweep"
user-invocable: true
---

# /regression-sweep — Whole-Sprint Regression Verification

`ship-ui`/`ship-non-ui` already gate every delivery on `tsc && lint && test`, plus (for `ship-ui`)
a `browser-verify` smoke check of the screen just built. That covers layers 1–2 of the three-layer
termination check (syntax/static → runtime/unit) and a narrow slice of layer 3 (system/end-to-end)
scoped to one delivery. Unit tests are structurally blind to wiring problems by design — a change
to a shared hook/component/query can pass every one of those gates clean and still break a screen
it didn't touch directly. This skill is the layer-3 check across an entire sprint's worth of
deliveries at once: does everything that shipped still actually work, together, in the running
app?

This is a heavyweight, whole-sprint pass — run it at sprint end or before a release, scoped to
whatever tickets shipped since the last sweep. It is **not** a per-feature gate; `ship-ui`/
`ship-non-ui`'s own gates stay as they are for that (see `Related` at the bottom).

Four phases: **Scope & Plan → Execute → Fix → Sign-off & Register**. Phase 2 runs unattended via
`/loop` across real wall-clock time; the other three are foreground work.

## Invocation

- **Explicit scope:** `/regression-sweep 113 109 102 103 87 89 105 98 144` — sweep exactly these
  tickets.
- **Auto scope (no args):** read the last sweep's `SPRINT-DELIVERY.md` sign-off date (see Phase 4);
  find every ticket in `docs/tickets/INDEX.md` with `updated` after that date. If no prior sweep
  exists, halt and ask the user to name the tickets explicitly rather than guessing a start point.

There is deliberately no separate "smoke mode" vs. "full mode" toggle at the invocation level.
Depth is driven per-ticket (Phase 1, Depth & Blast Radius) — a manual mode knob on top of that
would be a second, competing way to control the same thing. Don't pre-build a control nobody has
hit friction with yet (harness-engineering §7: the same discipline that says "remove a component
if nothing degrades without it" applies to not adding one in the first place). A fast pre-merge
sanity check short of a full sweep is already covered elsewhere: `ship-ui`/`ship-non-ui`'s own
Phase 2 `browser-verify` smoke check, or invoking this skill with an explicit single-ticket scope
(which gets that ticket its own assigned depth without a separate toggle).

## Working Directory

Same convention as `ship-ui`/`ship-non-ui`'s delivery working directory: the directory the user
names, else default to `docs/temp/regression-<YYYY-MM-DD>/` (the date this sweep starts — not a
sprint number, which isn't guaranteed stable the way a date is). Resolve once at the start of
Phase 1, reuse for every artifact below.

## Phase 1: Scope & Plan

The genuinely new phase this skill adds on top of the loop engine (Phase 2) — a scenario catalog
has to exist and be confirmed before anything gets dispatched.

For each ticket in scope:

### 1. Read its knowledge first

`docs/tickets/<id>/CONTEXT.md` frontmatter, then `PROGRESS.md`/`WALKTHROUGH.md` if the ticket
registry has them (per `ship-ui`'s "Registering Cross-Session Context" step, this is usually
already there). Acceptance criteria and prior decisions live there — don't re-derive them from the
diff.

### 2. Score depth: `ticket-effort` baseline + blast-radius floor

Score the ticket with `ticket-effort`'s existing 6-dimension complexity score — reuse it as a
starting point, not the final word:

| `ticket-effort` complexity | Baseline scenario catalog depth |
|---|---|
| trivial / simple | Smoke: 1–2 scenarios — does the changed screen/flow render and does the one changed interaction work |
| moderate | Light catalog: the happy path plus 1–2 edge cases named in the ticket's ACs |
| complex / very complex | Full catalog: walk every AC, one scenario per distinct behavior |

**This baseline is not sufficient on its own.** `ticket-effort` scores build difficulty, not
regression blast-radius, and those two can point opposite ways — a ticket that extends an existing
shared hook by following its pattern scores *low* on scope/domain-novelty precisely because it's
small and clean, which is exactly the profile that's dangerous to under-test: a shared seam
breaking affects every screen that consumes it, not just the one the ticket touched. Two required
adjustments on top of the baseline:

- **Blast-radius floor.** Check whether the ticket's diff touches a hook/component/query/service
  with other consumers (grep for other importers). If it has any consumer outside its own screen,
  floor the depth at "light catalog" regardless of what `ticket-effort` says, and add one scenario
  per additional consuming screen — verifying that screen still renders and behaves correctly
  against the changed dependency, not re-testing the whole consuming screen's own feature set.
- **No-UI-surface handling.** A `ship-non-ui` ticket (Cloud Function, Firestore rule, schema
  change with nothing rendered) can legitimately score "complex" on data-integrity or
  verification-surface dimensions while having no screen for an `agent-browser` scenario to click
  through. Don't force an artificial browser scenario onto it. If the change has no UI-visible
  effect anywhere, record it in `TEST-PLAN.md` as **"verified by its own delivery's test suite, not
  a browser scenario"** — stated explicitly, never silently dropped from the catalog. If the change
  *does* feed a screen, scenario depth follows that screen's own blast radius as above, not the
  backend ticket's own complexity score.

### 3. Research known gaps — every BLOCKED/EXPECTED-FAIL call needs a citation

No seed fixture, requires fault injection outside `agent-browser`'s reach, or an AC already
confirmed not implemented. **A `BLOCKED`/`EXPECTED-FAIL` entry means the execution loop never
dispatches a subagent for that scenario at all** (Phase 2 preserves the original's
structurally-blocked exception exactly) — a wrong call here is never independently checked by
anything downstream, so it needs its own evidentiary bar, not a guess that "looks" blocked. Every
such entry must carry a citation: a `file:line` for a confirmed-not-implemented claim, or an exact
quote from the ticket's own `CONTEXT.md`/`PROGRESS.md` for a structural/fixture gap.
`templates/TEST-PLAN-template.md`'s accepted-gaps section has a mandatory `Evidence` field for
this — no row is valid without one. Small per-ticket research notes go in `research/<id>-facts.md`
if genuinely needed; don't force this file into existence for a smoke-depth ticket that doesn't
need it, but the citation itself is required regardless of file size.

### 4. Author cross-ticket sync scenarios — don't stop at the per-ticket catalog

Step 2's depth table only ever produces scenarios scoped to one ticket. The highest-value scenario
shape is the opposite: a live, cross-role, cross-ticket sequence — submit as one role, act on it as
another role in a second live session, confirm the first session does **not** auto-update, then
confirm the working refresh path (navigate away and back) picks it up. This is the direct proof of
"nothing pushes automatically" and exactly the class of wiring bug unit tests are structurally
blind to — the core justification for this skill existing at all.

After the per-ticket catalog is drafted: identify any group of in-scope tickets that share a
live-data seam (same screen, same underlying query/cache, an approval-then-view flow spanning two
roles) and author at least one cross-ticket sync scenario per such group. These get their own row
in the **Cross-cutting Scenarios** subsection of `TEST-PLAN.md` (a `Tickets` — plural — column, not
a single `Ticket` column) — never forced into a single-ticket row shape.

### 5. Negotiate the sprint contract before dispatching anything

Harness-engineering's sprint-contract principle: scope + verification standard + explicit
exclusions, negotiated *before* the generator starts. Once the catalog is drafted, present the
scope, the accepted-gap list, and the depth-per-ticket table to the user as one batch of
questions/confirmations — same "batch all ambiguities at once" rule `ship-ui` Phase 1 follows.
Don't start the loop on an unconfirmed catalog.

### 6. Write `TEST-PLAN.md`

In the working directory, from `templates/TEST-PLAN-template.md`: ground rules (reseed-once,
refresh convention, viewport/session conventions — these are fixed project conventions, copy from
`docs/how-to-fe-test/CONTEXT.md`, don't restate ad hoc), then the scenario catalog grouped by
ticket, the Cross-cutting Scenarios subsection, and the cited accepted-gaps list.

### 7. Resolve execution order and write `LOOP-PROMPT.md`

**This step, not the running loop, is responsible for turning the catalog's `Depends-on` column
into one precomputed, linear, line-grouped scenario-ID execution list.** Some scenarios
legitimately depend on an earlier one's state (e.g. a summary-card scenario that computes its
"before" state from an approval scenario's baseline) — get the ordering explicit and correct here,
with a note on which orderings are load-bearing versus cosmetic. Leaving an unattended wakeup agent
to derive this order live from a dependency graph is strictly riskier than resolving it once, up
front, with the full catalog in view — getting it wrong produces wrong expected values, not just
untidy sequencing, and nobody is watching a given wakeup to catch that (harness-engineering §8's
"cognitive surrender" risk in an unattended loop). `TEST-PLAN.md`'s `Depends-on` column stays as
the documented *why*; the literal execution list — not the dependency graph — is what gets baked
into `LOOP-PROMPT.md` from `templates/LOOP-PROMPT-template.md`, along with this sweep's working
directory path.

**Completion criterion:** `TEST-PLAN.md` and `LOOP-PROMPT.md` both exist in the working directory,
the sprint contract is confirmed with the user, and every scenario ID in the catalog has a place in
the precomputed execution list.

## Phase 2: Execute

Hand `LOOP-PROMPT.md` to `/loop` in dynamic-pacing mode (`ScheduleWakeup`) — this is genuinely
long-running and unattended (real wall-clock gaps between wakeups, persistent named
`agent-browser` sessions), so it belongs on the loop primitive rather than a single foreground
session. Each wakeup:

```
1. Read RESULTS.md fresh — never trust memory across wakeups.
2. Zeroth: check for a capped-out scenario (see Phase 3, fix-attempt cap) or an
   unresolved FAIL from an interrupted prior wakeup — handle those before anything else.
3. Otherwise, find the next scenario ID with no row yet, walking the precomputed
   linear execution list LOOP-PROMPT.md already contains (Phase 1 step 7) — never
   recompute an order from the Depends-on column live.
4. If the ID is one of Phase 1 step 3's cited structurally-blocked entries, append its
   BLOCKED/EXPECTED-FAIL row directly with the citation — no dispatch spent.
5. Otherwise, dispatch exactly one subagent for that scenario. Its prompt must
   contain, verbatim or by exact file pointer: an instruction to load `browser-verify`
   first, then follow this project's own frontend-testing runbook doc, if one exists
   (check for something like docs/how-to-fe-test/CONTEXT.md or similar) and
   TEST-PLAN.md's conventions;
   confirmation that named agent-browser sessions are already logged in (check with a
   snapshot, don't blindly re-login); the exact scenario row it's responsible for,
   copied verbatim; the parts of each ticket's CONTEXT.md that row depends on; the
   status definitions (PASS/FAIL/EXPECTED-FAIL/BLOCKED/INCONCLUSIVE); the screenshot
   convention for visual-claim scenarios.
6. Require the subagent's report back in exactly this format:
   <ID>: <STATUS> — <one-line note> [screenshot: <path-or-—>]
   A result only exists once a subagent has actually driven agent-browser and observed
   the outcome — never infer, assume, or fill in a status from what a scenario
   "should" produce.
7. Append the result to RESULTS.md, commit: docs(regression-<date>): record results
   for <ID..ID>.
8. If a genuine FAIL surfaced (not predicted as BLOCKED/EXPECTED-FAIL) → go to Phase
   3 before continuing the catalog. Otherwise → decide whether to continue (unresolved
   IDs remain, schedule next wakeup) or stop (every ID has a row, proceed to Phase 4).
```

**Reseed exactly once**, during the very first wakeup only — never again mid-sweep, regardless of
how stale the emulator data looks. Re-seeding mid-sweep invalidates every already-recorded row's
baseline (dates, cycle state). "Refresh" always means navigate away and back — pull-to-refresh is a
documented dead no-op on this web build.

## Phase 3: Fix

Triggered by a genuine `FAIL` — one `TEST-PLAN.md` did not already predict as `BLOCKED`/
`EXPECTED-FAIL` for that ID.

1. Stop advancing through the catalog. **WIP=1: fix only the specific defect behind this one
   `FAIL`.** If the subagent's report mentions something else that looks off (a UX nit, a copy
   issue unrelated to this defect), note it in the `RESULTS.md` row and move on — fixing it is out
   of scope for this cycle.
2. **Fix-attempt cap, counted from `RESULTS.md` itself:** count how many rows for this exact
   scenario ID already exist with Status `FAIL`, including the one just appended. If this count is
   now **3**, stop — do not attempt another fix. Append one final row for this ID with Status
   `FAIL` and note `"unresolved after 2 fix attempts — needs human triage"`, commit, and **stop the
   entire sweep** (not just this ID) — do not schedule another wakeup, do not touch any other
   scenario. If the count is 1 or 2, proceed with the fix below.
3. Diagnose using the ticket's own `CONTEXT.md` — its ACs and prior decisions already answer "why
   does this exist," don't re-derive from scratch.
4. Fix test-first — this repo's TDD law (`CLAUDE.md`: "No test, no code," confirmed-seam
   requirement, one seam/test/minimal-implementation cycle at a time) applies here exactly as it
   does to any other code change, mid-sweep or not.
5. Run `tech-lead-review-with-fix` on the change. It interactively asks "Proceed with fixes?" and
   "Apply nitpicks?" — in this unattended context, treat its stated defaults as the answer every
   time (proceed with 🔴/🟡, skip 🔵). If it flags a finding as genuinely ambiguous, don't guess —
   record it in the `RESULTS.md` row's note as unresolved and fall through to the fix-attempt-cap
   handling above.
6. Run the project's three gate commands — **full suite, unfiltered** — and confirm zero errors.
   Read them from `.claude/harness.config.json`'s `gates.typecheck`/`gates.lint`/`gates.test`; fall
   back to `npm run tsc && npm run lint && npm test` only when that config file doesn't exist. This
   is separate and mandatory; `tech-lead-review-with-fix` doesn't run the full suite (only the
   project's test command against each file it edits).
7. Regression: re-run the scenario that failed, plus anything `TEST-PLAN.md` marks as depending on
   that ticket/screen, and confirm they now read `PASS`. Same dispatch format as Phase 2 step 5.
8. Update the `RESULTS.md` row(s) — prefix the note with `FIXED:`, append rather than overwrite so
   the trail survives (both rows keep the same ID, oldest first).
9. Commit the fix separately from the `RESULTS.md` update: `fix(<module>): <what changed>
   (regression sweep <date>, ticket <id>)`.

## Phase 4: Sign-off & Register

Once every scenario ID has a terminal row:

1. Write `SPRINT-DELIVERY.md` from `templates/SPRINT-DELIVERY-template.md`, scoring these five
   criteria explicitly, each met-or-not with evidence:
   - **Every ticket named in the sweep's scope is accounted for in `TEST-PLAN.md`** — as scenarios,
     as part of a cross-cutting group, or as an explicit no-UI-surface note — none silently absent.
     Check this first and separately from the criteria below: a no-UI-surface ticket can
     legitimately produce zero scenario IDs, so "every scenario ID has a terminal row" no longer by
     itself proves every ticket was covered.
   - Every scenario ID has a terminal row (`PASS`/`EXPECTED-FAIL`/`BLOCKED` with a stated
     resolution, or `FAIL` capped for triage).
   - Every genuine `FAIL` that surfaced is now `FIXED` and re-verified, or explicitly triaged to a
     human with a reason.
   - Every `BLOCKED` row has a stated decision: **extend seed data and re-run** — meaning
     re-invoke `/regression-sweep <ticket-id>` in explicit-scope mode once the fixture gap is
     closed, not a bespoke follow-up artifact — or **accept as untested this sweep and track
     separately**. Never left silent.
   - No accepted-gap list item was silently waved through as passing.
2. For every ticket covered, add a pointer line to its `docs/tickets/<id>/CONTEXT.md` — "verified
   in regression sweep `<date>`, see `<path>/RESULTS.md` / `SPRINT-DELIVERY.md`" — same convention
   `ship-ui`/`ship-non-ui` use for `PROGRESS.md`/`WALKTHROUGH.md`. This is also what makes
   auto-scoping the *next* sweep possible (Invocation, above) without extra bookkeeping — the
   ticket registry's `updated` field already carries what's needed.
3. Regenerate the registry: `node docs/tickets/update-tickets-index.mjs`.
4. Stop the loop.

## Templates

`templates/` in this skill directory:

- `TEST-PLAN-template.md` — ground rules; per-ticket scenario row format
  (`ID | Ticket | Steps | Expected | Depends-on`); a **Cross-cutting Scenarios** subsection with a
  `Tickets` (plural) row format; an accepted-gaps section with a mandatory `Evidence` field.
- `LOOP-PROMPT-template.md` — the wakeup procedure above, with the ticket-specific parts (the
  precomputed linear execution list, the working directory) left as fill-in slots. The execution
  list must be fully resolved (Phase 1 step 7) before this file is written — never a
  fill-in-later placeholder.
- `SPRINT-DELIVERY-template.md` — the five sign-off criteria above as a fill-in-the-evidence
  checklist.
- `RESULTS-header.md` — the results table's header row.

## Key Behaviors

| Rule | Detail |
|---|---|
| Plan before dispatch | `TEST-PLAN.md` + confirmed sprint contract before any subagent dispatch |
| Depth scales with complexity + blast radius | `ticket-effort` complexity label sets a baseline; a fan-out check floors depth for widely-consumed changes regardless of that score — no separate manual mode toggle |
| Cross-cutting scenarios authored explicitly | Ticket groups sharing a live-data seam get their own sync scenario, not just per-ticket rows |
| Blocked/expected-fail calls are cited | Every entry that skips a dispatch carries a `file:line` or exact doc quote — never a guess |
| One scenario per dispatch | Never batched, even for scenarios sharing a ticket/section |
| Execution order precomputed | The linear ID list is resolved once at plan-build time and baked into `LOOP-PROMPT.md`; the loop never recomputes order live |
| Pass-state gating | A status is only written after an actual `agent-browser` observation |
| External state only | Every wakeup re-reads `RESULTS.md`; nothing carried in context across wakeups |
| WIP=1 on fix | One genuine `FAIL`, one defect, nothing else touched |
| Fix-attempt cap from disk | 3 `FAIL` rows for one ID → stop the entire sweep for human triage |
| Reseed once | First wakeup only, never again mid-sweep |
| Sign-off is scored | `SPRINT-DELIVERY.md` against the 5 generic criteria (incl. ticket coverage), every `BLOCKED` resolved explicitly |
| Register cross-session | Pointer line into every covered ticket's `CONTEXT.md`, registry regenerated |

## Persistence

Keep `TEST-PLAN.md`, `LOOP-PROMPT.md`, `RESULTS.md`, `SPRINT-DELIVERY.md`, `research/*.md`
(if any), and `screenshots/` in the working directory after sign-off — do not delete them. They're
the durable, documented record of the sweep, and `SPRINT-DELIVERY.md`'s sign-off date is what the
next sweep's auto-scope reads.

## Related

- `Skill({skill: "browser-verify"})` — the actual driving mechanics (`agent-browser` conventions,
  phone viewport, two-width layout checks) this skill's Phase 2 dispatches lean on.
- `Skill({skill: "tech-lead-review-with-fix"})` — used in Phase 3 to review each fix before the
  mandatory `tsc`/`lint`/`test` gate.
- `Skill({skill: "ticket-effort"})` — supplies the baseline complexity score in Phase 1 step 2.
- `Skill({skill: "ship-ui"})` / `Skill({skill: "ship-non-ui"})` — the per-delivery pipelines this
  skill does not replace; see each one's own `Related` section for the reverse pointer.
