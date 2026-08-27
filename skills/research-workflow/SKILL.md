---
name: research-workflow
description: Research an unimplemented feature or topic and produce an implementation-ready design proposal, via a fixed 4-stage agent pipeline — external pattern survey, internal codebase/architecture mapping, domain-term validation (with a mechanically-detected escalation path), and an opus-driven synthesis stage that makes the actual design call and cites every recommendation back to the research. Use whenever the user wants to research how to build or design a new feature before writing code, survey how other products solve something before designing this project's own version, validate a new domain term against the project's own glossary before it becomes canon, or produce a PROPOSAL.md / design doc for something not yet built — trigger even on casual phrasing like "look into how other tools do X before we build it" or "research Y for our app." This is a fixed specialization of workflow-builder — read that skill first for the model-routing rubric and independent-review machinery this one reuses rather than re-deriving.
---

# Research Workflow

This packages one specific, previously-validated shape from `workflow-builder`: research a
not-yet-built feature or topic and land on a single, cited, actionable proposal. If the task
doesn't fit this shape — it's not "research X before building it," it's implementation, an
audit, or something with a different stage count — use `workflow-builder` directly instead of
forcing this fixed shape onto it.

**Inputs needed before starting:** a topic/feature name, a one-line description of what it
needs to do, and a target output directory. If either is missing, ask rather than guessing —
the stage prompts below depend on both.

## The fixed shape

Four stages, always in this order, always these four:

1. **External research** — survey ≥4 real, distinct products/patterns with sourced claims,
   ending in a comparison table.
2. **Internal mapping** — map the topic onto this project's own documented architecture and
   conventions, find an existing analogous pattern to build from if one exists.
3. **Domain-term validation** — stress-test any new domain term(s) this feature introduces
   against the project's own glossary; end in either a resolved definition or a literal
   `UNRESOLVED:` marker.
4. **Synthesis** — reconcile 1–3 into one proposal that makes the actual design call, cites
   every recommendation back to a research file, states what was explicitly rejected and why,
   and closes with what remains genuinely open.

Full prompt skeletons for all four stages are in `references/stage-prompts.md` — read it and
fill in the placeholders for this specific topic rather than writing the stages from scratch.
Reusing these skeletons is what keeps citation discipline, the escalation marker, and the
"trace every claim back to a file" rule consistent across every run of this skill.

## Steps

1. **Confirm the two inputs** (topic + target directory) and locate this project's own
   architecture doc, domain-glossary doc, and conventions/design-system doc (whatever this
   project calls them — every project names these differently). Stage 2 and 3's prompts need
   these paths.

2. **Score the four stages** against
   workflow-builder's `references/scoring-rubric.md`. In practice this shape
   converges reliably: Stages 1–3 usually land in the 7–11 band (`sonnet`) because they're
   citing/mapping/interrogating against existing material, not inventing it; Stage 4 usually
   hits uncertainty=3 (`opus`) because synthesis-with-no-spec is what it does by definition.
   Score honestly anyway rather than assuming the pattern holds — a topic with unusually low
   novelty could legitimately push a stage down to `haiku`, and that's a real cost saving
   worth catching.

3. **Write the file set** using `workflow-builder`'s step 3 (its `assets/templates/`),
   pre-filling the stage table with this shape's four rows. Add one thing this shape always
   needs that a generic workflow might not: in `CONTEXT.md`'s escalation section, state
   explicitly that Stage 3's `UNRESOLVED:` marker triggers a Stage 3 re-run (not a skip to
   Stage 4) at the escalated model, and that the re-run's output *replaces* the original
   file rather than appending to it — this exact ambiguity broke the first workflow this
   pattern was built from.

4. **Run `workflow-builder`'s independent review (R1)** against the draft before executing
   anything. Don't skip this because the shape is "already proven" — the shape being fixed
   doesn't make a specific run's file paths, project doc references, or escalation wiring
   correct by default.

5. **Execute**: spawn Stages 1–3 concurrently (they don't depend on each other), write back
   any stage whose `subagent_type` lacks `Write` (check this — `Explore` and most
   interrogation-style agents typically do lack it), grep Stage 3's output for the
   `UNRESOLVED:` marker and re-run at the escalated model if present, then spawn Stage 4 once
   all three research files exist. Verify Stage 4's floor check — every one of the three
   research filenames actually appears cited in `PROPOSAL.md` — before flipping its
   `TASKS.md` row to `passing`.

**Completion check:** `PROPOSAL.md` exists, cites all three research files by name multiple
times (not once in a header), states at least one thing explicitly rejected and why, and
closes with an open-questions section that wasn't silently resolved. If any of those four are
missing, Stage 4 isn't actually done — re-run it with a sharper prompt before marking the row
`passing`.
