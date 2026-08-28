---
name: spec-builder
description: Turn a ticket ID, a rough idea, a scratch note, or a link into a build-ready spec (SPEC.md) — researching what's actually needed, drafting the spec, then walking the user through every design-critical call before it's ever handed to a delivery pipeline. Only invoke on an explicit /spec-builder request; never trigger this from casual conversation about a feature, since it creates a real ticket and can spend a real research pass.
disable-model-invocation: true
argument-hint: "a ticket ID, a rough idea/note, or a link"
---

# Spec Builder

This is the planning half of a two-skill pipeline. `spec-builder` turns something rough — an
idea, a ticket ID, a link, half a thought — into a spec you can trust enough to hand to a delivery
skill (`ship-ui`/`ship-non-ui`) without re-deriving what you meant. Delivery skills stay
delivery-only; this skill never implements anything.

The one rule everything else here serves: **you see and sign off on every drafted spec, every
time.** Nothing here is about skipping your review — it's about making the parts that don't need
your judgment cheap, so the parts that do get your full attention instead of getting rushed. If a
decision genuinely has more than one reasonable answer, you make the call, in plain language, with
the actual tradeoff in front of you — never a guess baked silently into a draft.

## Input

Accept whatever the user hands over — don't require it to already look like a proper ticket:

- **An existing ticket ID** — read `docs/tickets/<id>/CONTEXT.md`.
- **Informal raw material** — a scratch note, a half-formed thought, a pasted doc, not yet a user
  story.
- **A bare link/URL** — fetch it generically (`WebFetch`); it may already carry enough context on
  its own. Don't assume any particular source system for it.

## Phase 0 — Normalize and register

Synthesize a real `title` + one-line `description` from whatever was given, however rough. Do
this even from a fragment — always attempt a best-effort read rather than stopping to ask for more
structure. The reason this is safe: every draft gets reviewed by the user later (Phase 4), so a
normalization that's slightly off just surfaces as a spec about the wrong thing, correctable at
the cost of one research pass — not a shipped mistake. The one real stop is genuinely empty input:
that's a missing argument, not something to interpret.

If the ticket doesn't exist yet:
1. Scan `docs/tickets/` for the current highest numeric ID; the new ticket is `max + 1`.
2. Create `docs/tickets/<id>/CONTEXT.md` with real `title`/`description` frontmatter — you already
   have real content, so don't write the `TBD` stub `update-tickets-index.mjs --init` produces for
   directories that lack any content at all.
3. Regenerate `docs/tickets/INDEX.md` (`node docs/tickets/update-tickets-index.mjs`).

Do this before Phase 1 — you can't decide how much research a ticket needs until you know what
it's actually asking for.

## Phase 1 — Decide how much research this needs

Most tickets don't need a full research pass; a few genuinely do. Route on one question: **does
this project's own documentation already answer what's needed to draft correctly** — the relevant
module `CONTEXT.md`, canonical docs, related ticket history?

- **Docs already cover it → light path.** Draft directly from what you just read. No separate
  workflow, no research artifacts — go straight to Phase 2.
- **Docs don't cover it → heavy path.** This is what "insufficient" actually means: drafting would
  require inventing a domain rule, validating an undefined term, or working out how similar
  products solve something unfamiliar. Invoke the `research-workflow` skill, unmodified — don't
  reach for a lighter version of it or skip stages; if the task fits that skill's shape, use it as
  it exists. Give it the ticket's title, one-line description, and
  `docs/tickets/<id>/RESEARCH/` as the target output directory. Read the `PROPOSAL.md` it produces
  before moving to Phase 2.

Make this call yourself — don't ask the user to pick a tier. Getting it wrong is cheap: it shows
up as an under-informed draft (which the user will send back) or as research spent on something
that didn't need it, never as a mistake that ships. That low cost is exactly why this can be
decided automatically instead of adding another thing the user has to answer per ticket.

## Phase 2 — Draft `SPEC.md`

Write `docs/tickets/<id>/SPEC.md`. Its job is different from `ship-ui`'s own `PLAN.md`, and it's
worth keeping that boundary clean rather than duplicating effort:

- **`SPEC.md` (this skill) answers:** what's being built, why, the critical decisions with the
  actual choice that was made (once Phase 4/5 resolve them), and — as of Phase 3.6 — the
  ticket-level **Acceptance Criteria**: the numbered, Gherkin checklist that decides whether the
  ticket is delivered.
- **`PLAN.md` (ship-ui's own Phase 1, later) answers:** files to touch, implementation order, and
  any finer-grained implementation-level criteria (e.g. a wireframe's element-by-element inventory)
  — derived *from* this spec's Acceptance Criteria, once they exist, not re-derived from scratch.

Don't reach into file-list or implementation-order territory here; that's the next skill's job, and
it does it better once the ambiguity is already gone. Acceptance criteria are the one exception —
this skill owns the ticket-level checklist because it's downstream of the same critical-decision
resolution this skill already does; ship-ui/ship-non-ui refine it to implementation grain, they
don't originate it.

## Phase 3 — Classify what's actually critical

Have a **separate pass** read the finished `SPEC.md` cold — no memory of having drafted it — and
mark which parts are design/architecture-critical versus which are safe to skim. This has to be a
different pass than the one that wrote the draft: whoever just wrote something is the worst-placed
reader to notice their own quiet assumptions, the same way proofreading your own writing misses
what a second reader catches instantly. Spawn it as a fresh subagent with only `SPEC.md` and the
reference below, not the drafting context.

Read `references/severity-classification.md` for the full test and the reviewer's exact brief —
it also has the plain-language template every critical item must use in Phase 4. The short version
of the test: **this is never about which folder a change would land in.** It's about whether
building this spec as written requires a real business-rule decision, a boundary crossing between
this project's own documented layers, or a project-structure/coding-guideline call — versus
something presentation-only, which is cheap to redo if it's wrong. A change that looks like pure
UI work can still hide a business-rule decision (e.g. "just compute this value in the component" is
architecture-relevant even though it never leaves a view file) — read for what's actually being
decided, not for which directory the words point at.

Write the raw output of this pass to `docs/tickets/<id>/REVIEWS/iteration-NN/severity-
classifier.md` (NN starts at 01, increments each time this phase re-runs), then fold it into a
running `docs/tickets/<id>/REVIEWS/FINDINGS.md`. This isn't paperwork for its own sake — it's what
lets a later session (or you, next week) see why a decision landed where it did, without having to
reconstruct it from a conversation that's since scrolled away.

If the `Write` tool refuses a path like `REVIEWS/FINDINGS.md` (a harness guard against report-
sounding filenames can catch this, unrelated to anything this skill is doing wrong), fall back to
writing the same content to the same path via `Bash` (e.g. a heredoc). The content and location
matter, not which tool put it there.

## Phase 3.5 — Verify what the classifier merely asserted

Phase 3 writes plausible options, not verified ones — it reads `SPEC.md` cold with no codebase
access, so it can't confirm a factual claim even when one shows up in an option's tradeoff (a file
count, "this pattern already exists," any specific number). Left unchecked, a wrong number ships to
the user framed exactly like one that was actually checked. This phase is where that gets caught,
before Phase 4 ever presents it.

Grep the just-written `severity-classifier.md` for the literal `UNVERIFIED:` marker (see
`references/severity-classification.md` for what triggers it). Skip this phase entirely if there
are no hits — most tickets won't have any.

For each hit, spawn one scoped `Agent` call — not a full `research-workflow` run, just a single
targeted check against the real codebase/docs: "does implementing X actually touch 5 files, or
more, and which ones." Write its answer to `docs/tickets/<id>/RESEARCH/verify-<slug>.md`, then fold
the corrected fact — citing that file — back into `FINDINGS.md` in place of the `UNVERIFIED:`
marker. Never let the marker itself reach Phase 4.

If a verification agent comes back saying the claim is bigger than a fact-check — the decision
actually hinges on how other products or an undocumented domain rule handle it, not just a count in
this codebase — escalate that one item to a full `research-workflow` run scoped to it (topic = the
one decision, output dir = `docs/tickets/<id>/RESEARCH/<slug>/`), the same escalation shape Phase 5
already uses for a rippling resolution. Most items resolve with the single check; this is the
exception, not the default.

## Phase 3.6 — Draft acceptance criteria

Besides the critical items Phase 3 surfaces, `SPEC.md` needs one more thing before it's ready to
present: the hard checklist that decides whether the ticket is actually delivered. This is a
narrower job than Phase 3 — it doesn't re-read the spec for judgment calls, it just pulls out
what's already there in checkable form — so run it as its own bounded loop rather than folding it
into the classification pass.

Each criterion must be:

- **Specific** — a pass/fail check, not a matter of taste. "The feature works well" fails this test;
  "when the user submits the form with an empty required field, the field shows its error message
  and the form does not submit" passes it.
- **Numbered**, so anything downstream (a PR description, a reviewer, a QA plan) can reference it by
  ID — `AC-01`, `AC-02`, zero-padded two digits, sequential.
- **Written as Gherkin** — Given/When/Then — so what's required to consider the ticket done reads
  clearly without translation:

  ```
  ### AC-01: <short, specific title>
  - **Given** <the starting state/context>
  - **When** <the action or event>
  - **Then** <the specific, observable outcome>
  ```

**Two agents, maker/checker, bounded 6:** `spec-ac-writer` drafts the list, `spec-ac-reviewer`
checks it for coverage, format, and specificity — same collect/settle shape as Phase 3, and the same
"implementer iterates until the reviewer is satisfied" loop `ship-ui`'s own QA-plan phase uses,
capped lower here (6, not 10) because a criteria list is a narrower, better-defined artifact than a
full test plan. Loop artifacts live under `docs/tickets/<id>/REVIEWS/ac/iteration-NN/`:

```
ITERATION = 0
LOOP:
  ITERATION += 1
  mkdir -p REVIEWS/ac/iteration-$(printf %02d "$ITERATION")

  1. Spawn spec-ac-writer — iteration 1: fresh draft from SPEC.md; iteration > 1: hand it its own
     prior draft plus this iteration's review feedback → write to
     REVIEWS/ac/iteration-NN/draft.md
  2. Spawn spec-ac-reviewer on that draft → write to REVIEWS/ac/iteration-NN/review.md
  3. If verdict == approved → promote draft.md into SPEC.md's own `## Acceptance Criteria`
     section, exit loop
  4. If ITERATION == 6 and verdict != approved → promote the current draft.md anyway, append the
     reviewer's unresolved findings as a "Known Gaps" note at the top of that section, exit loop
```

```
Agent({subagent_type: "harness-plugin:spec-ac-writer", description: "Draft the Acceptance Criteria section of SPEC.md — numbered, Gherkin-format, one entry per independently-checkable behavior."})

Agent({subagent_type: "harness-plugin:spec-ac-reviewer", description: "Review the Acceptance Criteria draft at REVIEWS/ac/iteration-NN/draft.md for coverage, Gherkin format, and specificity."})
```

**A criterion can't outrun an unresolved decision.** If a behavior genuinely depends on a critical
item that's still open, the writer doesn't guess at one of the options — it writes the criterion as
far as it honestly goes and marks the outcome `**Then** PENDING-DECISION: <the critical item's
number/title>`, the same discipline as Phase 3.5's `UNVERIFIED:` marker. When that item is later
resolved in Phase 5, resolving it also clears its `PENDING-DECISION` markers — see Phase 5.

**Model routing (ticket-effort principle):** `spec-ac-writer` pins `model: sonnet` and
`spec-ac-reviewer` pins `model: haiku` in their own agent frontmatter — translating spec prose into
concrete, falsifiable Gherkin takes real interpretation, auditing that result against an explicit
format/coverage checklist doesn't. Escalate `spec-ac-reviewer` to `model: "sonnet"` per-invocation
only when this ticket's requirements are genuinely high-stakes or ambiguous; never past `sonnet` for
either agent.

## Phase 4 — Present, once

Show the user `SPEC.md` with the classification applied, as one document, read once — not a
question-by-question interrogation. Lead with a short count (how many critical items, how many
presentation-only), then critical items first, presentation-only after, then the Acceptance Criteria
checklist from Phase 3.6. By this point every option's factual claims are either checked (Phase 3.5)
or explicitly still open — nothing reaches you framed as settled that was never actually confirmed.
Any `PENDING-DECISION` line in the checklist should read as a visible consequence of the critical
item it cites, not a separate mystery — point back to that item's number when you present it.

**Every critical item must be genuinely readable without outside context.** That's not a style
preference here — it's load-bearing, because the whole point of surfacing something as critical is
that the user can actually evaluate it and decide. A tag that just says "touches architecture" or
leans on a function name to carry the explanation isn't a flag the user can act on, it's a flag
they have to go translate first. Use exactly the three-part shape from
`references/severity-classification.md`: the real-world situation being decided, why it's a
judgment call and not something the docs already settle, and the honest options if there's a known
set of them. File and function names are a footnote for whoever implements it later — never the
explanation itself.

## Phase 5 — Resolve, iterate, or finish

The user responds in plain language — approve as drafted, resolve specific critical items, or send
the whole thing back for another pass. Capture their resolution straight into `SPEC.md`'s decision
record yourself; don't hand them the file to edit by hand, that's the authoring cost this skill
exists to remove.

When a critical item gets resolved, apply the **same test from Phase 1** to the resolution itself,
not a new one: does this only settle that one item, or does it ripple — contradict something else
already in the spec, or open a question that wasn't there before? A local resolution just patches
the record and you move on. A rippling one starts a new iteration (same `REVIEWS/iteration-NN`
convention as Phase 3) scoped to what actually changed — re-examine the affected sections and
re-classify; only fall back to a full `research-workflow` re-run if the ripple is itself genuinely
open-ended, not just because a resolution touched more than one line (same escalation shape as
Phase 3.5).

Resolving a critical item also settles any Acceptance Criteria line that was marked
`PENDING-DECISION` against it. Re-run the Phase 3.6 loop (same bounded-6, same `REVIEWS/ac/iteration-
NN` convention) scoped to just the affected lines — hand the writer the resolution and the specific
`AC-NN` lines it unblocks, not the whole checklist. A resolution that touches no `PENDING-DECISION`
line needs no re-run.

Finished when nothing critical remains unresolved, no Acceptance Criteria line is still marked
`PENDING-DECISION`, and the user says so. At that point `SPEC.md` is what gets handed to
`ship-ui`/`ship-non-ui` — point it at the file; there's nothing else to wire up.

## File layout

```
docs/tickets/<id>/
  CONTEXT.md            # registry entry (Phase 0, if the ticket is new)
  SPEC.md               # this skill's output — what ship-ui/ship-non-ui consume
  RESEARCH/              # heavy path (Phase 1) and per-claim (Phase 3.5) output
    verify-<slug>.md      # Phase 3.5 — single-claim fact-checks
    <slug>/                # Phase 3.5 escalation — full research-workflow scoped to one decision
  REVIEWS/
    iteration-NN/severity-classifier.md
    FINDINGS.md
    ac/iteration-NN/draft.md      # Phase 3.6 (and its Phase 5 re-runs) — AC writer/reviewer loop
    ac/iteration-NN/review.md
```

## A note on where this runs

This skill is written to work in any project, not just this one — it reads whatever project it's
currently running in's own `CLAUDE.md` and architecture docs at runtime (see
`references/severity-classification.md`) rather than assuming any specific folder names. Treat any
project-specific example you see anywhere in this skill as an illustration, never a rule to match
literally.
