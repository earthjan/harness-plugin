# Independent Review Checklist

Give this to the separate reviewer agent (no prior context on the draft) spawned for R1.
It's the same set of questions that caught real, blocking bugs the first time this skill's
pattern was used — don't skip any of them because the draft "looks fine."

## 1. Operability — can this literally run?

- For every stage in the orchestration diagram, does its named `subagent_type` actually have
  the tools the stage needs? In particular: can it `Write` its own output file, or does the
  orchestrator need to persist the returned text on its behalf (and does `CONTEXT.md` say so
  explicitly, not just imply it)?
- Is every escalation/branch condition mechanically detectable — a literal string an
  orchestrator can `grep` for — or is it something only a human would reliably notice? A
  branch without a concrete trigger isn't a real branch.
- Does the orchestration diagram show the escalation as a real serial step (with the barrier
  correctly placed after it resolves), or is it a parenthetical comment that leaves timing
  ambiguous?
- If a stage's output file can be overwritten by a re-run (an escalation, a retry), does the
  design say what happens to the file — replaced in place, or merged? Undefined overwrite
  semantics is a real bug, not a nitpick.

## 2. Instructions (harness-engineering §1)

- Is `CONTEXT.md` self-contained enough that a session with zero prior context on this task
  could pick it up and run it? Could it answer: what is this, how do I run it, how do I
  verify it, what's the current state?
- Is anything in `CONTEXT.md` asserted as already true (e.g. "this was reviewed and
  finalized") when `TASKS.md`/`PROGRESS.md` don't actually back that claim up yet? This is a
  live self-contradiction, not a style issue — flag it even if it seems like a small wording
  slip.

## 3. State (harness-engineering §3)

- Does `PROGRESS.md` actually capture *why*, not just *what*? Code/files survive a reset;
  reasoning doesn't unless it's written down.
- Is R1 itself wired into something — even if that something is "the user manually spawns
  it" — or does the design describe R1 as required without ever saying how it gets
  triggered?

## 4. Scope control (harness-engineering §4)

- Does every `TASKS.md` row have the full triple: behavior, verification, state? Missing any
  one and it's a memo, not a feature-list primitive.
- Is pass-state gating real, or decorative? If "whoever reads the output file" is always the
  same session that spawned the stage, that's orchestrator self-check, not independent
  review — the design should say so honestly rather than borrowing maker/checker language it
  doesn't actually deliver on.

## 5. Verification (harness-engineering §5)

- Does each verification criterion have at least a partial mechanical/grep-able check, or is
  it 100% prose judgment where a mechanical floor check was actually available and skipped?

## 6. Graph justification (harness-engineering §9)

- Does the design's own claim about which graph-justification criteria hold actually survive
  scrutiny, or is it filled in to hit "3 of 5" without real backing? In particular: check
  whether the stated "branch path" is actually a branch (a real fork in what happens next)
  or just a barrier being mislabeled as a branch.

## 7. Model routing sanity check

- Read `MODEL-ROUTING.md`. Pick the two dimensions most likely to be inflated to justify a
  predetermined model choice, and check them against what the stage's prompt actually asks
  for — not against the model someone might have wanted.
- Is every Opus route named with a specific trigger (genuine ambiguity, irreversible
  precedent, no existing spec), not just "this is complex"?

## Output

Give a blunt findings list: file + what's wrong + a specific fix, not "improve this." Then a
verdict: does the design pass as-is, or what MUST change before anyone runs it? Separate
must-fix (operability or self-contradiction bugs) from should-fix (things that would improve
rigor but don't block a first run). Do not edit any files — output the review as text only,
for the orchestrating session to apply.
