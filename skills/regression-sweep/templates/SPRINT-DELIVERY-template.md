# Regression Sweep Sign-Off — <date>

Tickets covered: `<id, id, id, ...>`
Working directory: `<working directory path>`
Prior sweep referenced for auto-scope: `<path to previous SPRINT-DELIVERY.md, or "none — first sweep">`

Score each criterion explicitly — met or not, with evidence. Do not mark a criterion met without
citing the row(s)/file(s) that prove it.

## 1. Every in-scope ticket is accounted for

Checked first and separately from the criteria below — a no-UI-surface ticket can legitimately
produce zero scenario IDs, so criterion 2 no longer by itself proves every ticket was covered.

- [ ] Met / Not met
- Evidence: for each ticket in scope, cite where it appears in `TEST-PLAN.md` — its own scenario
  section, a cross-cutting group, or an explicit no-UI-surface note. Flag any ticket that appears
  in neither.

## 2. Every scenario ID has a terminal row

- [ ] Met / Not met
- Evidence: `RESULTS.md` row count vs. `TEST-PLAN.md` scenario-ID count; list any ID missing a
  terminal (`PASS`/`EXPECTED-FAIL`/`BLOCKED`-with-decision/capped-`FAIL`) row.

## 3. Every genuine FAIL is resolved or triaged

- [ ] Met / Not met
- Evidence: list every ID that had a genuine `FAIL` row; for each, cite the `FIXED:`-prefixed
  re-verification row, or the `"unresolved after 2 fix attempts"` triage row.

## 4. Every BLOCKED row has a stated decision

- [ ] Met / Not met
- Evidence: for each `BLOCKED` row, state which path applies — "extend seed data and re-run" (name
  the follow-up `/regression-sweep <ticket-id>` invocation this defers to) or "accept as untested
  this sweep, tracked separately" (name where it's tracked). No `BLOCKED` row left without one.

## 5. No accepted-gap item silently passed

- [ ] Met / Not met
- Evidence: cross-check `TEST-PLAN.md` §5's accepted-gaps list against `RESULTS.md` — confirm every
  gap-list ID's row status matches what was predicted (`BLOCKED`/`EXPECTED-FAIL`), not quietly
  upgraded to `PASS` without re-review.

## Overall call

**Sweep delivered:** Yes / No — <one-line reason if No>

## Follow-ups

- <any deferred fixture gaps, tracked-separately items, or flagged findings that aren't blocking
  this sign-off but need eyes later>
