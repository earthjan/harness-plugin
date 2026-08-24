# Regression Sweep Test Plan — <date> (tickets: <id, id, id, ...>)

**Read each covered ticket's `CONTEXT.md` first.** Every claim in this plan (what's stubbed, what's
a known gap, what shipped vs. what the ticket literally asked for) is sourced there or cited
directly below — this file only adds the executable steps.

**Audience:** an autonomous agent driving `agent-browser` against the Firebase emulator + seeder,
following `docs/how-to-fe-test/CONTEXT.md`. This is a runbook, not a narrative — follow it in
order, record results as you go, don't skip the pre-flight.

---

## 0. Ground rules before you start

1. **Reseed immediately before this session**, not from a stale run. Every date-derived field
   (`isLate`, due dates, grace windows) is computed off real wall-clock time at seed time — see
   `docs/how-to-fe-test/CONTEXT.md`.
2. **Pull-to-refresh does nothing in this environment.** Wherever this plan says "refresh," it
   means: **navigate away to another screen, then navigate back.**
3. Scenarios below marked **BLOCKED** cite the reason they cannot currently be observed (§4). Don't
   improvise a workaround — record them as blocked with the citation, so the gap is visible in the
   final sign-off rather than silently skipped.
4. Scenarios marked **EXPECTED-FAIL** cite the confirmed-not-implemented AC behind them (§4).
   Running them confirms the gap still exists; it is not new-bug discovery.
5. Anything not called out as blocked/expected-fail is a genuine pass/fail check — a `FAIL` there
   is real and should be reported as a finding.

## 1. Pre-flight setup

```bash
# Terminal 1 — start emulators, leave running
npm run emulators

# Terminal 2 — once emulators are up, seed fresh data
npm run seed:emulator
```

```bash
# Two isolated logins, phone viewport
agent-browser open http://localhost:8081/login --session admin
agent-browser set viewport 412 914
# sign in as admin@dev.test / password

agent-browser open http://localhost:8081/login --session participant
agent-browser set viewport 412 914
# sign in as participant@dev.test / password
```

Confirm `.env.local` has `EXPO_PUBLIC_ENABLE_DEV_EMAIL_AUTH=true` before starting.

Re-check any scenario flagged as a visual/layout issue at the narrower Z Fold width too
(`agent-browser set viewport 344 882`) before concluding it's a real bug.

## 2. Global conventions

- **Session naming:** `--session admin` / `--session participant`. Reuse these two names
  throughout.
- **Screenshots:** only for scenarios making a visual/layout claim. Save under
  `screenshots/<scenario-id>-<role>-<width>.png`.
- **"Current cycle" and lateness are time-dependent.** Never assume a specific cycle is "Now" or
  "Late" from this document — verify against what the app shows at test time.

## 3. Per-ticket scenario catalog

One subsection per ticket in scope. Depth per ticket follows `SKILL.md` Phase 1 step 2 (baseline
complexity + blast-radius floor) — state which depth tier applied and why, in one line, at the top
of each subsection.

### Ticket <id> — <title> (depth: <smoke | light | full> — <one-line reason>)

| ID | Steps | Expected | Depends-on |
|---|---|---|---|
| `<ID>-1` | <executable steps> | <expected outcome> | <— or another scenario ID> |

If this ticket has no UI-visible effect anywhere (`SKILL.md` Phase 1 step 2's no-UI-surface
handling), replace the table with one line:

> Verified by its own delivery's test suite, not a browser scenario. `<file:line or delivery
> reference>`.

## 4. Cross-cutting scenarios

Scenarios spanning more than one ticket's screens via a shared live-data seam (`SKILL.md` Phase 1
step 4). One row per sequence — a sequence with multiple numbered steps gets recorded as one
`RESULTS.md` row; if it doesn't cleanly pass, the report must say which numbered step failed and
how.

| ID | Tickets | Steps | Expected | Depends-on |
|---|---|---|---|---|
| `<ID>` | `<id>, <id>` | <numbered live-sequence steps — act in one role's session, confirm no push in the other, confirm refresh path picks it up> | <expected outcome per step> | <— or another scenario ID> |

## 5. Accepted gaps (BLOCKED / EXPECTED-FAIL)

No row is valid without an `Evidence` citation — a `file:line`, or an exact quote from the ticket's
own `CONTEXT.md`/`PROGRESS.md`. A guess that something "looks" blocked is not sufficient.

| ID | Status | Reason | Evidence |
|---|---|---|---|
| `<ID>` | BLOCKED / EXPECTED-FAIL | <one-line reason> | `<file:line>` or `"<exact quote>" (source)` |

## 6. Execution order

See `LOOP-PROMPT.md` for the precomputed linear execution list resolved from this catalog's
`Depends-on` columns (`SKILL.md` Phase 1 step 7). This section documents the *why* for every
load-bearing ordering constraint; the list itself lives only in `LOOP-PROMPT.md`.

- `<ID>` must run before `<ID>` — <reason, e.g. "computes its baseline from the earlier scenario's
  post-state">.
