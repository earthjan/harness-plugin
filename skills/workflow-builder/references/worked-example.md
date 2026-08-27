# Worked Examples

Two different shapes, to show this skill isn't only a research-pipeline builder. Read
whichever one is closer to the task at hand — you don't need both.

## Example 1 — a 4-stage research pipeline (real, ran end to end)

Full file set: `docs/temp/supporting-activity-logs/` in the `bayaned` project (`CONTEXT.md`,
`MODEL-ROUTING.md`, `TASKS.md`, `PROGRESS.md`, `research/*.md`, `PROPOSAL.md`). This is the
concrete pattern `research-workflow` packages as a fixed specialization of this skill — read
that skill if the task at hand actually *is* "research a feature and produce a design doc."

Shape: 3 independently-decomposable research stages run in parallel (external pattern
survey, codebase/architecture mapping, domain-term validation), a conditional escalation
inside one of them (an `UNRESOLVED:` marker in the domain-validation output triggers a
re-run at a higher model), then a hard-barrier synthesis stage that reconciles all three into
a single proposal. Scores: 8/18, 7/18, 10/18 for the three parallel stages (all `sonnet`),
14/18 with uncertainty=3 for the synthesis stage (`opus`, named trigger: "genuine
architecture decision spanning modules with no existing spec"). The independent review (R1)
caught two real operability bugs before it ran: two of the four subagent types couldn't
`Write` their own output files, and the escalation marker wasn't actually mandated in the
stage's prompt spec, just described in the meta-docs.

## Example 2 — an implementer/reviewer feature-build (illustrative, not run)

A different shape from Example 1: two stages, not four, and no parallel fan-out — it's a
straight-line maker → checker pair, which is the harness-engineering "Sub-agents (maker ≠
checker)" primitive in its simplest form.

**Task:** "add rate limiting to the public API and have someone independently check it."

| Stage | What it does | Scoring sketch | Model |
|---|---|---|---|
| 1. Implement | Add rate-limiting middleware, config, tests | scope 2 (one service, a few files) · domain novelty 2 (new rule: sliding-window limits, edge cases around burst traffic) · uncertainty 1 (the ticket specifies limits and scope) · integrity 2 (affects every API caller if wrong) · judgment depth 1 (implementation, not a first-of-its-kind design call) · verification 2 (needs unit + integration coverage) → **11/18 → `sonnet`** |
| 2. Review | Independently check the diff against the project's own rate-limiting conventions (if any), the ticket's acceptance criteria, and load-bearing edge cases (concurrent requests, clock skew, restart behavior) | scope 1 (reads a diff + docs) · domain novelty 1 (checking against an existing rule, not inventing one) · uncertainty 1 (the diff + ticket fully specify what "correct" means) · integrity 2 (a missed edge case here ships a real bug) · judgment depth 1 · verification 2 (must actually exercise the edge cases, not just read code) → **8/18 → `sonnet`** |

No escalation branch here — this shape doesn't need one, because neither stage's output can
trigger a conditional re-run of the other. `TASKS.md` still needs both rows with real
verification (stage 1's is "tests pass, `yarn tsc`/`yarn lint` clean"; stage 2's is "review
findings list exists, each finding is either fixed or explicitly deferred with a reason").
R1 (the workflow-design review) still applies even to a two-stage shape this simple — it's
what would have caught, for instance, "stage 2 can't actually run the app to test concurrent
requests" if that turned out to be true of the reviewer's tool access.

## What generalizes across both

- However many stages, score each one independently against
  `references/scoring-rubric.md` — don't let a shared "this whole task is hard" feeling
  inflate every stage's score uniformly.
- A workflow doesn't need parallel fan-out or an escalation branch to justify this skill —
  even a straight-line two-stage maker/checker benefits from explicit scoring, a real
  `TASKS.md`, and an independent R1 review, because those are what keep the *next* person
  (or the next session) from having to re-derive why the design looks the way it does.
- The independent review is not optional scaffolding — in Example 1 it found bugs that would
  have broken the workflow on its first real run. Skipping R1 to save one agent call is a
  false economy on anything more than a single-stage task.
