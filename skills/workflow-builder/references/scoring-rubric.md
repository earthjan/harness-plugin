# Stage Scoring Rubric (single source of truth)

This is `/ticket-effort`'s 6-dimension rubric, with the reasoning-effort tier dropped. Both
`workflow-builder` and `research-workflow` read this file rather than restating it — if the
thresholds ever change, this is the one place to edit.

## Why the effort tier is gone

`/ticket-effort` derives two things from a 6-dimension score: a reasoning-effort label
(`low`/`medium`/`high`/`xhigh`/`max`) and a model. A workflow built with this skill spawns
each stage through the `Agent` tool, and `Agent` only accepts a `model` override — there is
no effort parameter to attach a tier to. So this rubric keeps the score and the model, and
throws the effort label away. Nothing else about the scoring changes.

## The 6 dimensions (0–3 each)

Score every stage against these. When evidence is thin, take the lower score and note the
assumption — don't round up to make a stage look more justified than it is.

| # | Dimension | 0 | 1 | 2 | 3 |
|---|---|---|---|---|---|
| 1 | **Scope** — how much this stage touches | one file/source/doc | 1–2 sources in one area | cross-layer or cross-source | cross-module, spans the whole task |
| 2 | **Domain novelty** — restating known patterns vs. inventing new ones | pure restatement | light adaptation | new rule with edge cases | new concept/invariant |
| 3 | **Uncertainty** — how well-defined this stage's question already is | fully specified | minor gaps, resolved by reading docs | real ambiguity, needs a judgment call | no existing spec at all |
| 4 | **Integrity/risk** — cost of this stage being wrong | no downstream dependency | informs, doesn't decide | narrows future options | sets a hard-to-reverse precedent |
| 5 | **Depth of judgment required** — how much taste/design sense this stage needs (call this "UI/UX depth" only when the stage is literally UI work; for a non-UI workflow read it as "how much of the answer is judgment vs. lookup") | none | describes existing patterns | proposes new structure/handling | makes a standalone design decision |
| 6 | **Verification surface** — how much cross-checking this stage's own output needs | none | cite one source | cross-reference a few sources | reconcile conflicting sources |

**Total = sum of six (0–18).**

## Score → model (no effort label)

Evaluate top-down; first match wins. This is the exact routing logic `/ticket-effort` uses
to pick a model, with the effort labels stripped out — the reasoning behind each threshold
lives in `/ticket-effort`'s own SKILL.md if you want the full justification.

| Total | Model | Condition |
|---|---|---|
| ≥16, or uncertainty=3, or (integrity=3 with irreversible/architecture impact) | `opus` | Name the specific trigger in the stage table's "Why" column — never route here on total alone. This is the one legitimate place for Opus: a stage genuinely making an unrecoverable call with no existing spec to fall back on. |
| 12–15 | `sonnet` by default; `opus` only if uncertainty is *also* ≥2 | Complexity alone isn't the trigger — compounding ambiguity is. |
| 8–11 | `sonnet` | The workhorse tier — most real stages land here. |
| 4–7 | `sonnet`, unless scope≤1 and domain-novelty≤1 → `haiku` | Narrow *and* mechanical only — a stage that's just executing an already-documented pattern with no cross-layer reach. |
| ≤3 | `haiku` | Cheap default. |

**Cost-efficiency principle:** most workflows should land the majority of their stages on
`sonnet`, with `haiku` for the genuinely mechanical ones and `opus` reserved for the one or
two stages that actually make an irreversible call. If every stage in a draft scores 12+,
that's a signal the decomposition is too coarse — split it further rather than routing the
whole thing to `opus`.

## Working the rubric honestly

Two traps to watch for when scoring your own stages:

- **Post-hoc justification.** If a stage's score conveniently lands exactly where you
  already wanted the model to be, re-derive each dimension from what the stage's prompt
  will actually ask the agent to do, not from the model you'd prefer to use.
- **Synthesis stages tautologically score `uncertainty=3`.** Any stage whose job is "make
  the final call with no existing spec" will always self-score into the Opus trigger,
  because that's the definition of synthesis. That's not wrong, but don't present it as
  task-specific rigor — name it plainly as "this stage synthesizes with no spec, which is
  what synthesis stages do" rather than implying the workflow uncovered something unique.
