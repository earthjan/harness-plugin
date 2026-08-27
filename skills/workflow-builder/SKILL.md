---
name: workflow-builder
description: Design a maker/checker multi-agent workflow for any task that decomposes into independently-checkable stages — scores each stage against a ticket-effort-style rubric to route it to the cheapest sufficient model (haiku/sonnet/opus, via the Agent tool's model override), writes a CONTEXT.md/MODEL-ROUTING.md/TASKS.md/PROGRESS.md file set at a target directory, and mandates an independent review pass before the workflow is treated as ready to run. Use whenever the user wants to build, design, or set up a multi-stage agent workflow, an implement-then-review pipeline, a research pipeline, an audit or migration workflow, or any task that should fan out across several Agent calls with per-stage model selection — even without the word "workflow": "spawn some agents to do X and Y then have someone check it", "set up a maker/checker loop for...", "I want a pipeline that does A, B, then reconciles them". The stage-decomposition test and model-scoring rubric are adapted from harness-engineering and ticket-effort methodology, fully inlined in this skill's own references/ — no separate skill install needed. For a fixed research-a-feature-and-produce-a-proposal shape specifically, use research-workflow instead, which specializes this skill.
---

# Workflow Builder

A **workflow**, here, is a set of `Agent` calls with an explicit stage decomposition, a
scored model choice per stage, and an independent review before it runs. It exists because a
single agent call either underuses cheap stages (running everything on one expensive model)
or overuses the expensive one (letting the hardest stage's needs set the tier for stages that
didn't need it). Building one by hand every time reinvents the same five files; this skill
makes that reinvention mechanical.

Two worked examples — a 4-stage research pipeline and a 2-stage implement/review pair — live
in `references/worked-example.md`. Skim whichever is closer to the task before drafting; the
point is that this skill fits both shapes and everything between them, not just one.

## 1. Decompose into stages

Break the task into stages using harness-engineering's graph-justification test: does the
work independently decompose, are there real branch/checkpoint points, does every stage have
an explicit checkable "done"? If the task is genuinely one seam with no independent
sub-parts, this skill is overkill — a single `Agent` call at one scored model is the right
answer, and forcing a multi-stage shape onto it just adds ceremony. Most real tasks do
decompose, though: a maker + an independent checker is already two stages; research tasks
split by information source; audits split by dimension.

Name each stage, one sentence each, before scoring anything — scoring an underspecified
stage produces an underspecified score.

## 2. Score each stage and pick a model

Read `references/scoring-rubric.md` in full — it has the six dimensions and the score→model
table. Score every stage independently against it; resist letting one stage's "this is hard"
feeling bleed into the others' scores. Write the worked scoring as you go — you'll need it
verbatim for `MODEL-ROUTING.md`.

Watch for the two traps the rubric file names explicitly: scoring backward from a model
you'd already prefer, and treating "this stage synthesizes with no spec" as if it were a
unique discovery rather than what every synthesis stage always scores.

If a conditional escalation makes sense for a stage (its own output determines whether a
higher model re-runs it — e.g. an unresolved conflict, a low-confidence result), define the
exact literal marker the orchestrator will `grep` for now, not later. A branch nobody can
mechanically detect isn't a branch a workflow can actually take.

**Completion check:** every stage has a total score, a resulting model, and — for any Opus
route — a one-clause named trigger (not "this is complex").

## 3. Write the file set

Copy the four templates in `assets/templates/` to the user's target directory, stripping the
`.template` suffix, and fill in the placeholders:

- `CONTEXT.md` — the entry file: goal/verification/stopping-condition triple, the stage
  table (score + model + why), the orchestration diagram naming exact `subagent_type` +
  `model` per stage, explicit write-back instructions for any subagent type without `Write`,
  and concrete escalation mechanics.
- `MODEL-ROUTING.md` — the worked scoring per stage from step 2.
- `TASKS.md` — one feature-list row per stage (behavior + verification + state), plus the
  R1 self-review row that ships in the template already.
- `PROGRESS.md` — starts with one entry: the workflow was drafted, and why the stages/models
  landed where they did.

Before filling in the orchestration diagram, check what tools each `subagent_type` you're
naming actually has (a read-only search/explore agent type typically lacks `Write`) — this
is exactly what determines whether that stage needs the orchestrator's write-back
instruction. Getting this wrong is the single most common way a first draft fails review.

**Completion check:** all four files exist, every `TASKS.md` row has a real behavior +
verification + state, and nothing in `CONTEXT.md` claims the design is finished, reviewed,
or final — that claim isn't true until step 4 actually happens.

## 4. Independent review (R1) — do not skip this

Spawn one separate `Agent` call with **no prior context on the draft** — a fresh
`general-purpose` agent, any model, told to read `references/review-checklist.md` and apply
it to the four files just written. This agent's only job is to find what's wrong; it doesn't
get to also be the one who wrote the draft, because that agent's blind spots are exactly what
a genuinely independent pass exists to catch.

Give it the checklist file path and the target directory, and tell it explicitly: cite
file+finding+fix, don't edit anything, end with a verdict (pass as-is / must-fix list).

**Completion check:** a real findings list exists (even if it's empty), and the review
distinguishes must-fix (operability bugs, self-contradictions) from should-fix (rigor
improvements). "Looks fine" without having actually read the checklist is not a review.

## 5. Apply fixes and log them

Apply every must-fix finding. Apply should-fix findings unless there's a stated reason not
to (note the reason if you skip one). Append one `PROGRESS.md` entry summarizing what R1
found and what changed — this is the record that lets a future session trust the design
without re-deriving it. Flip `TASKS.md`'s R1 row to `passing` only now, once the findings are
actually addressed — not when the review agent merely returns.

**Completion check:** `PROGRESS.md` has a review entry naming real findings (not "no issues
found" unless the review genuinely found none), and R1 is `passing`.

## 6. Execute

Run the orchestration exactly as `CONTEXT.md` specifies: spawn each stage's `Agent` call at
its named `model`, write back any non-`Write`-capable stage's returned text to its named
path, check escalation markers where defined and re-run at the escalated model if triggered,
then run the barrier/synthesis stage once its prerequisites exist. After each stage, verify
its `TASKS.md` row's criterion actually holds before flipping it to `passing` — the stage's
own agent doesn't get to do that for itself.

**Completion check:** every `TASKS.md` row (including R1) is `passing`, and `PROGRESS.md`
has one entry per stage explaining what it found and why, not just that it ran.
