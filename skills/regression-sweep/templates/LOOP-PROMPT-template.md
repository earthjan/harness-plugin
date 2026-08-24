# Loop prompt — Regression sweep <date> → fix → sign-off

You are re-entering this loop after a wakeup. Your own memory of prior iterations is not
reliable — **the files in this directory (`RESULTS.md`, `SPRINT-DELIVERY.md`, git log) are the
only source of truth for what's already done.** Re-read them fresh every time before deciding what
to do next. Do not trust anything you "remember" about state from earlier in this session.

Working directory: `<working directory path>`
Tickets in scope: `<id, id, id, ...>`

## Step 0 — Am I already done?

If `SPRINT-DELIVERY.md` already exists in this directory, the sweep is complete. Do nothing else —
no reseed, no dispatch, no commit. Stop the loop immediately.

## Step 0a — Is this the very first wakeup? (one-time setup)

Check: does `RESULTS.md` exist in this directory yet?

- **If it does not exist**, this is the first wakeup:
  1. Confirm `.env.local` has `EXPO_PUBLIC_ENABLE_DEV_EMAIL_AUTH=true`.
  2. Start the emulators (`npm run emulators`, left running) if not already running.
  3. Reseed: `npm run seed:emulator`. **This is the one and only reseed for the entire sweep** —
     never again on any later wakeup, regardless of how stale the data looks.
  4. Open and log in both named `agent-browser` sessions: `--session admin`, `--session
     participant`, at viewport `412 914`. These persist across every later dispatch in this loop.
  5. Create `RESULTS.md` with only the header row from `templates/RESULTS-header.md` — no
     pre-filled rows.
  6. Commit: `git add <working directory>/RESULTS.md && git commit -m "docs(regression-<date>):
     initialize RESULTS.md"`.
- **If `RESULTS.md` already exists**, skip all of the above, including the reseed — go to Step 1.
  Stale-looking data on a later wakeup is expected drift from real wall-clock time passing; verify
  in-app what's currently shown and adapt, don't reseed.

## Each wakeup, after Step 0/0a

1. **Read `RESULTS.md`.**
   - **Zeroth, check for a capped-out scenario:** if any ID's last row has Status `FAIL` and a note
     starting with `"unresolved after 2 fix attempts"`, the loop already stopped itself for human
     triage. Do not attempt another fix. If you are running at all with such a row present, stop
     again immediately, touching nothing.
   - **Otherwise, check for an unresolved `FAIL`:** if a previous wakeup was interrupted mid-fix
     (a `FAIL` row with no later `FIXED:`-prefixed `PASS` row for the same ID), skip straight to
     step 6 for that ID before anything else.
   - **Otherwise**, find the first scenario ID with no row at all yet, walking this precomputed
     execution list left to right — every ID on one line finishes before any ID on the next line
     starts:

   ```
   <line-grouped scenario ID execution list, resolved from TEST-PLAN.md's Depends-on
   columns per SKILL.md Phase 1 step 7 — fully resolved before this file was written,
   never a fill-in-later placeholder>
   ```

2. **Exception — no dispatch for cited BLOCKED/EXPECTED-FAIL IDs.** These are already determined
   by `TEST-PLAN.md` §5's own cited research — append their row directly with the status and the
   evidence quoted from the plan, no subagent dispatch spent. Every other ID gets its own solitary
   dispatch.

3. **Dispatch a subagent for exactly one scenario ID — never more than one per dispatch**, even two
   IDs that share a ticket section. Process the execution list one ID at a time in the order above,
   its result read and appended to `RESULTS.md` before the next dispatch.

   The subagent's prompt must contain, verbatim or by exact file pointer:
   - An instruction to load the `browser-verify` skill first, then follow
     `docs/how-to-fe-test/CONTEXT.md` and `TEST-PLAN.md`'s conventions (phone viewport,
     `--session admin`/`--session participant`, "refresh" = navigate away and back).
   - A note that `agent-browser`'s `admin`/`participant` sessions are already logged in from Step
     0a — confirm with a quick `agent-browser snapshot` rather than blindly re-running login.
   - The exact scenario row from `TEST-PLAN.md` it is responsible for, copied verbatim — exactly
     one row, never more.
   - The relevant parts of each covered ticket's `CONTEXT.md` those rows depend on.
   - The status definitions (`PASS`/`FAIL`/`EXPECTED-FAIL`/`BLOCKED`/`INCONCLUSIVE`) and the
     instruction to pick exactly one, with a one-line note.
   - The screenshot convention (only for visual-claim scenarios).

   Require its final report back in exactly this format:
   ```
   <ID>: <STATUS> — <one-line note> [screenshot: <path-or-—>]
   ```
   A result only exists once a subagent has actually driven `agent-browser` and observed the
   outcome — never infer, assume, or fill in a status.

4. **Append each returned line as a row to `RESULTS.md`**, in `templates/RESULTS-header.md`'s
   format, as soon as the subagent returns.

5. **Commit.** `docs(regression-<date>): record results for <ID..ID>`.

6. **If a genuine `FAIL` surfaced** (not already predicted `EXPECTED-FAIL`/`BLOCKED`) — stop
   advancing and fix it before continuing. **WIP = 1: fix only the specific defect behind this one
   `FAIL`.**
   - **Fix-attempt cap:** count how many rows for this exact scenario ID already exist with Status
     `FAIL`, including the one just appended. If **3**, stop — append one final row with Status
     `FAIL` and note `"unresolved after 2 fix attempts — needs human triage"`, commit, and **stop
     the entire loop** (not just this ID) — do not schedule another wakeup, do not touch any other
     scenario. If 1 or 2, proceed.
   - Diagnose using `docs/tickets/<id>/CONTEXT.md`.
   - Fix test-first: red → green, per `CLAUDE.md`'s TDD law. Non-negotiable, not satisfied by
     `tech-lead-review-with-fix` alone.
   - Run `tech-lead-review-with-fix` on the change. Treat its stated defaults as the answer every
     time in this unattended loop (proceed with 🔴/🟡, skip 🔵). A genuinely ambiguous finding →
     record unresolved in the `RESULTS.md` note, fall through to the fix-attempt-cap handling.
   - **Run all three required gates, zero errors:**
     ```bash
     npm run tsc
     npm run lint
     npm test    # full suite, unfiltered
     ```
     A fix is not done until all three are clean. Separate from `tech-lead-review-with-fix`, which
     only runs `npx jest <touched-file>`.
   - Regression: re-run the failed scenario plus anything `TEST-PLAN.md` marks as depending on that
     ticket/screen, confirm they now read `PASS`. Same dispatch format as step 3.
   - Update the row(s): prefix the note `FIXED:`, append rather than overwrite (both rows keep the
     same ID, oldest first).
   - Commit the fix separately from the results update:
     `fix(<module>): <what changed> (regression sweep <date>, ticket <id>)`.

7. **Decide whether to continue or stop:**
   - Any scenario ID from step 1's list still has no row → schedule the next wakeup, keep going.
   - Every ID has a row → write `SPRINT-DELIVERY.md` from `templates/SPRINT-DELIVERY-template.md`,
     scoring all five criteria explicitly. For every `BLOCKED` row, state the decision — re-invoke
     `/regression-sweep <ticket-id>` in explicit-scope mode once the fixture gap is closed, or
     accept as untested and track separately — never leave it silently unresolved.
   - Then, for each covered ticket, add a pointer line to `docs/tickets/<id>/CONTEXT.md` — "verified
     in regression sweep `<date>`, see `RESULTS.md`/`SPRINT-DELIVERY.md`" — and regenerate the
     registry: `node docs/tickets/update-tickets-index.mjs`.
   - Once that's done, stop the loop (no more wakeups needed) — the Step 0 check on the next wakeup
     will find `SPRINT-DELIVERY.md` and confirm nothing is left.

## Ground rules — don't relitigate these mid-loop

1. **Reseed exactly once**, Step 0a on the very first wakeup only.
2. **"Refresh" means navigate away and back, never pull-to-refresh.**
3. A genuine `FAIL` (not already predicted `BLOCKED`/`EXPECTED-FAIL`) blocks the sign-off — don't
   paper over it in `SPRINT-DELIVERY.md`.
4. Accepted gaps are exactly what `TEST-PLAN.md` §5 cites, with evidence — nothing else gets waved
   through.
