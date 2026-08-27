# Stage Prompt Skeletons

Fill in the `{{...}}` placeholders per invocation. These are skeletons, not fill-in-the-blank
forms — adapt the specifics (which products to survey, which docs to read, which glossary
term to validate) to the actual topic; keep the structural requirements (citation rules, the
output-file framing, the escalation marker) intact, since those are what make the later
stages and the verification checks actually work.

## Stage 1 — External research (`general-purpose`, model per scoring)

```
You are researching real, external designs for {{TOPIC}} — {{ONE_LINE_CONTEXT}}.

Survey at least 4 real, distinct products/patterns covering meaningfully different
approaches (not 4 sources describing the same approach). For each one, cover:
1. The UI/interaction pattern, if relevant.
2. The underlying data model / architecture, if relevant.
3. Whatever dimension actually matters for this topic (retention, versioning, latency,
   whatever the domain calls for — pick what's substantive, don't force this template).
4. Pros and cons specifically for this project's actual context: {{PROJECT_CONTEXT}}.

Cite a source URL for every factual claim about a specific product's behavior.

End with a comparison table across all 4+ patterns.

Your returned text will be saved verbatim by the orchestrator to `research/external-patterns.md`
— write it as a complete, standalone markdown document, not a conversational reply.
```

## Stage 2 — Internal mapping (`Explore`, model per scoring)

```
Working directory: {{REPO_ROOT}}

Read {{PROJECT_ARCHITECTURE_DOC_PATHS}} first, in that order, before searching any code.

Task: map where {{FEATURE_NAME}} would integrate into this codebase — which layer/module
owns which responsibility, per the documented architecture, and what existing pattern in
this codebase is the closest analog to build from (cite it directly if one exists).

Answer explicitly, each claim cited with a file:line or a doc section:
{{SPECIFIC_QUESTIONS_FOR_THIS_TOPIC}}

Also check {{DESIGN_SYSTEM_OR_CONVENTIONS_DOC}} for gaps this feature would inherit if built
naively, and what the minimal fix is.

Your returned text will be saved verbatim by the orchestrator to `research/codebase-map.md`
— write it as a complete, standalone markdown document.
```

## Stage 3 — Domain-term validation (`domain-griller` if available, else `general-purpose`)

Check whether the target project has a `domain-griller` subagent/skill available before
picking the fallback — it's built for exactly this interrogation.

```
Working directory: {{REPO_ROOT}}

Read {{DOMAIN_GLOSSARY_DOC_PATH}} as your domain-model source of truth.

Interrogate this proposed domain-model addition: {{PROPOSED_TERM(S)}}, describing
{{WHAT_THE_TERM_MEANS}}.

Stress-test relentlessly:
- Does it collide with any existing term in the glossary? Could a reader confuse them? If a
  collision is real, propose a name that avoids it.
- What is the minimal correct definition, and what are its relationships to existing terms —
  write it in the glossary's own term/definition/avoid style.
- What edge cases remain genuinely open (not resolvable from the existing docs alone)?

Do not accept the first framing if it's sloppy.

If you can fully resolve the term(s) without remaining ambiguity, end your output with a
"Resolved Definition" section in the glossary's own style.

If a genuine conflict cannot be resolved from the existing docs alone, end your output with
a line starting EXACTLY "UNRESOLVED:" followed by a one-sentence description of the
conflict. This exact token is mechanically grepped for afterward — use it only for a real
unresolved conflict, with the exact prefix and nothing before it on that line.

Your returned text will be saved verbatim by the orchestrator to `research/domain-validation.md`.
```

## Stage 4 — Synthesis (`general-purpose`, `opus` — this is the one stage that should almost
always land there; see below)

```
Read these three research files in full before writing anything:
1. {{TARGET_DIR}}/research/external-patterns.md
2. {{TARGET_DIR}}/research/codebase-map.md
3. {{TARGET_DIR}}/research/domain-validation.md

Also skim {{GROUNDING_DOCS}} for consistency — don't re-derive what's already in the
research files, just confirm nothing contradicts them.

Synthesize the three into a single, actionable design proposal — this is the stage that
makes the actual call, not one that catalogs options. Every recommendation must trace back
to something in one of the three files, cited by filename. Do not introduce a recommendation
that isn't grounded in 1, 2, or 3.

Sections:
1. Recommended domain term (per file 3).
2. Recommended primary approach — pick ONE (not a menu), justify it against this project's
   actual context, and state what you're explicitly NOT adopting and why.
3. The actual placement/integration call (per file 2) — resolve any "or" the research left
   open; don't leave it open if the research already answered it.
4. Concrete shape (record fields, API surface, whatever this topic's concrete deliverable
   is).
5. Any operational recommendation this topic needs (retention, rollout, versioning — pick
   what's substantive for this specific topic).
6. Open questions NOT resolved by this pass — pull forward everything genuinely unresolved
   across the three files. Do not silently resolve these yourself.

Your returned text will be saved verbatim by the orchestrator to `PROPOSAL.md` — write it as
a complete, standalone markdown document ready to hand to an implementation ticket.
```

**Why Stage 4 is (almost) always `opus`:** score it against
workflow-builder's `references/scoring-rubric.md` anyway — don't skip the
scoring step just because the answer is predictable — but expect uncertainty=3 every time,
because "make the final call with no existing spec" is what synthesis stages are. Name that
plainly in `MODEL-ROUTING.md` rather than dressing it up as a surprising finding.
