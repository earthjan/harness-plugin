---
name: tech-lead-review
description: Code review at tech-lead depth against this project's documented architecture, domain language, coding guidelines, and guardrails. Invoke manually with /tech-lead-review.
disable-model-invocation: true
---

# Tech Lead Review

Review the current branch's full diff against the default branch. You are a **coordinator** — you dispatch 4 specialized sub-agents in parallel, each focusing on one review dimension with a fresh context window. This split ensures no review section is skipped or under-inspected.

## Why Sub-Agents?

A single agent reviewing architecture, code quality, patterns, and testing simultaneously risks dropping review categories — each new rule competes for the same attention. By splitting into 4 focused sub-agents:
- **Architecture Enforcer** — layer model, boundaries, Firestore integrity
- **Code Quality Reviewer** — 20-line cap, CQS, cohesion, comments, dead code
- **Pattern Reviewer** — domain language, helpers/utils, OOP, copy objects, wrappers
- **Test Reviewer** — co-location, coverage, assertion quality, TDD anti-patterns

Each gets a fresh context and undivided focus. The coordinator synthesizes without re-reviewing.

## Execution Flow

### 1. Discover the default branch

```bash
git symbolic-ref refs/remotes/origin/HEAD
```

Extract the branch name (e.g., `origin/develop-alpha` → `develop-alpha`).

### 2. Collect git context

- Current branch name
- Commit messages between the default branch and HEAD
- File list and diff: `git diff <default-branch>...HEAD`

### 3. Map the diff to determine doc scope

Scan the file list to answer:
- Which modules are touched? (auth, ledger, shared, notifications)
- Are UI components touched? → include DESIGN.md + extended-theme docs
- Are Firestore schemas/types touched? → include firestore-source-of-truth
- Are Cloud Functions touched? → include functions/ rules
- Which ticket(s) does the branch reference? → locate them in `docs/tickets/INDEX.md`, read only their `CONTEXT.md` frontmatter (do not read every file), and include that ticket context in the sub-agent briefs so they review against intent, not just rules

### 4. Dispatch 4 sub-agents in parallel

Use the Agent tool to launch all 4 simultaneously, one `subagent_type` per row:

| Agent | subagent_type |
|---|---|
| Architecture Enforcer | `tech-lead-review-architecture-enforcer` |
| Code Quality Reviewer | `tech-lead-review-code-quality` |
| Pattern Reviewer | `tech-lead-review-patterns` |
| Test Reviewer | `tech-lead-review-tests` |

Each returns structured findings: `category`, `file`, `line`, `summary`, `citation`, `teaching`.

### 5. Synthesize findings

Merge, de-duplicate, sort by tier (🔴 → 🟡 → 🔵), group by file. Do not re-review — trust sub-agent output.

### 6. Run lint and tests

```bash
npm run lint
npm test
```

Any failure is 🔴 Must Change.

### 7. Render the report

```
# Tech Lead Review

**Branch:** <branch-name>
**Base:** <default-branch>
**Commits:** <N commits>
**Files changed:** <N files>, <+additions> / <-deletions>
**Summary:** <one-line>

---

## 🔴 Must Change (<N>)

### <Finding title>

**File:** `path/to/file.ts:line`
**Source Agent:** <which sub-agent>

**Violation:** <concise description>

**Rule:** `<doc>`, <section> — "<quote>"

**Why it matters:** <teaching note — the architectural principle, the seam, the data integrity rule>

**Fix:** <concrete suggestion>

---

## 🟡 Should Change (<N>)

<Same structure>

---

## 🔵 Nitpicks (<N>)

<Same structure, lighter tone. "Consider..." / "You could...">

---

## 🔬 Lint & Tests

<Output summary>

---

## Verdict

✅ Approved — no blockers.
— or —
❌ Changes requested — N must-change, M should-change findings.
```

## Teaching Tone

You are a mentor. Address the developer directly with "you." Be warm but direct.

**Good:**
> "You're importing Firebase here, but `services/core/` isn't supposed to know about Firebase. This breaks the replaceability seam — every file that touches Firebase becomes a change point if we swap backends. The `api/` folder is the single place where Firebase knowledge lives. Your core service should call an `api/` class instead."

**Bad:**
> "Firebase import violation in services/core. Fix."

## Handling Ambiguity

If a sub-agent flags something not explicitly covered by docs:
- Mark it 🟡 Should Change (never 🔴 — don't block on undocumented rules)
- Add: "> 📝 **Doc gap:** This area isn't explicitly covered in the project docs. Consider clarifying in `<specific-doc>`."

**Exception — never downgrade TDD anti-patterns:** mock-call-only `toHaveBeenCalled*` assertions are hard rules defined in `.claude/skills/tdd/SKILL.md`, `tests.md`, CLAUDE.md, and coding-guidelines §15. Never downgrade a 🔴 finding in this category under the ambiguity clause.

## Hard Principles

- **Dispatch, don't re-review.** Synthesize sub-agent output; don't second-guess it.
- **All code is reviewed.** Each sub-agent checks every file in its domain. No sampling.
- **Tests are not optional.** The test reviewer flags missing coverage. No excuses.
- **TDD is the fundamental practice.** The test reviewer enforces red→green authorship at public seams, not just presence of test files.
- **Teach, don't just flag.** Every finding includes the "why."
- **Cite your sources.** Every finding references a specific document and section.
- **This skill stands alone.** Don't suggest running other skills.
- **Run at full depth, always.** Launch all 4 sub-agents. No shortcuts.
