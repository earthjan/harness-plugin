---
name: instructions-readme-drift-check
description: "Quick-check CLAUDE.md and canonical docs for outdated or conflicting references against README architecture and guardrails. Use before revising CLAUDE.md or docs/*/CONTEXT.md files."
argument-hint: "What scope to check (all docs or selected files)?"
---

# Docs README Drift Check

Quickly detect whether CLAUDE.md and canonical docs under `docs/*/CONTEXT.md` are outdated relative to `README.md`.

## When To Use

- Before editing CLAUDE.md or canonical docs.
- After major README architecture updates.
- During review when documented behavior seems inconsistent with project source-of-truth.

## Outcome

Produce a concise drift report with:

- broken references (README sections or terms that no longer exist)
- semantic conflicts (doc says X but README says Y)
- scope drift (rules whose scope no longer matches folder responsibilities)
- stale examples (paths/terms no longer valid)
- a quick pass/fail decision for safe revision readiness

## Inputs

- `README.md` (source of truth)
- `CLAUDE.md` and all canonical docs under `docs/*/CONTEXT.md`
- optional scope filter for specific doc files

## Procedure

1. Build a README source-of-truth index.
2. Extract from README:
   - architecture boundaries (`api`, `query`, `query/cache`, `services`, `pages`, `components`)
   - decision table responsibilities
   - naming/file conventions
   - strict guardrails and non-negotiable rules
3. Scan each CLAUDE.md section and canonical doc:
   - explicit README references (section names, folder paths, rule names)
   - implicit claims about architecture responsibilities
4. Compare doc claims against README index.
5. Classify findings by severity:
   - `high`: direct contradiction with README source-of-truth
   - `medium`: stale/renamed references or misleading scope
   - `low`: weak wording, ambiguous references, non-blocking drift
6. Decide quick-check result:
   - `PASS`: no high/medium findings
   - `PASS-WARN`: only low findings
   - `FAIL`: any high finding or any medium finding
7. Output a compact report and recommended next edits.

## Decision Points

- If a doc and README disagree, treat README as authoritative.
- If a doc references a section title that changed but intent still matches, classify as `medium` (stale reference).
- If a rule's scope is broader than the stated responsibility, classify as `medium`.
- If rule wording is vague but not contradictory, classify as `low`.

## Report Format

Return results in this structure:

1. Quick Check Verdict: `PASS`, `PASS-WARN`, or `FAIL`
2. Findings by severity (high -> medium -> low)
3. Affected files with exact outdated references
4. Suggested minimal edits to restore alignment
5. Ready-for-revision decision: `yes` or `no`

## Quality Checklist

- Every finding points to a concrete file and quoted phrase.
- Every conflict includes the matching README rule/section.
- Suggested fixes are minimal and preserve existing intent when possible.
- Report remains short enough for pre-revision triage.

## Constraints

- Do not rewrite doc files during the quick check unless explicitly asked.
- Prefer identifying drift over proposing broad refactors.
- Keep the check lightweight and fast.
- Return concise recommendations only, not patch-ready diffs.
