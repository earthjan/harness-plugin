---
name: tech-lead-review-with-fix
description: Review branch changes with tech-lead agent, then apply fixes iteratively — the subagent reviews, the main agent fixes
user-invocable: true
---

# /tech-lead-review-with-fix — Review & Fix Loop

Spawns the `tech-lead-review` subagent to audit the current branch's diff, then applies fixes iteratively. The subagent is the reviewer (read-only); you (the main agent) are the fixer.

## Loop Flow

```
1. Collect git context (default branch, diff, commits)
2. Spawn tech-lead-review agent → report with structured findings
3. Present report to user
4. Apply 🔴 Must Change fixes (main agent edits files)
5. Apply 🟡 Should Change fixes (main agent edits files)
6. Offer 🔵 Nitpicks to user (apply or skip)
7. Re-spawn tech-lead-review agent to verify fixes
8. Report final verdict
```

Max 2 review-fix iterations: one round of fixes, one verification pass.

## Step-by-Step Execution

### Step 1: Collect Git Context

Discover the default branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD
```

Note the current branch, commit history, and file list for the report header.

If the branch references a ticket (a `docs/tickets/<id>/` directory exists), consult the registry — don't start zero-context: read `docs/tickets/INDEX.md` to locate it, then read only that ticket's `CONTEXT.md` frontmatter. Include the ticket context (title, description, state) in the review agent's brief.

### Step 2: Spawn tech-lead-review Agent

Spawn the review agent on the full diff, passing the ticket context from Step 1:
```
Agent({subagent_type: "harness-plugin:tech-lead-review", description: "Review branch diff against default branch. Ticket context: <title/description/state from docs/tickets/<id>/CONTEXT.md>"})
```

The agent loads all canonical docs, runs the rulebase, and produces the report. Wait for it to finish before proceeding.

### Step 3: Present Report to User

Display the review report as-is. Summarize the counts:
- 🔴 Must Change: N
- 🟡 Should Change: M
- 🔵 Nitpicks: P

Ask: "Proceed with fixes?" (Default: yes. If user says no, stop here.)

### Step 4: Apply 🔴 Must Change Fixes

For each must-change finding, in order of appearance:
1. Read the target file
2. Apply the suggested fix (or a better approach if obvious)
3. Use `git add <file>` to stage the fix
4. Mark the finding as fixed

If a fix needs clarification, flag it and move on — don't get stuck. Collect all ambiguous findings and ask the user once at the end.

**Applicability:** the test-pattern-by-layer guidance below (React component/hook, service class, utility function) is one illustration — lista-natin's own stack (React/React Native + Jest + Testing Library). Before applying it, check this project's own `CLAUDE.md`/coding-guidelines for its actual test framework and layer conventions (if `CLAUDE.md` is missing or silent here, check a sibling `CLAUDE.local.md` for an `@`-import line, e.g. `@../CLAUDE.md`, and follow one such hop), and map the same principle (assert observable behavior through the public interface, mock only system boundaries) onto whatever that project's idiom is. For the test-runner invocation, use `.claude/harness.config.json`'s `gates.test` value if set (drop any `--no-coverage`-equivalent single-file flag the project's runner supports, to keep the check fast); fall back to `npx jest <test-file> --no-coverage` only when that config file doesn't exist and the project is in fact Jest-based.

**When the finding is a missing test file (🔴 Must Change for coverage):**
1. Read the source file to understand its public interface (exported functions, component props, class methods).
2. Create `<SourceFileName>.test.ts` in the **same directory** as the source file (co-located, per this project's own naming conventions — check its `CLAUDE.md`). Do NOT create a `__tests__/` subdirectory unless that's what the project's own convention documents.
3. Match the test pattern to the file's layer and this project's own stack — for example, in a React/React Native + Testing Library project:
   - **React component:** `render(<Component />)` with at least one `expect(screen.getByText(...) / getByTestId(...) / getByRole(...)).toBeInTheDocument()`. Provide required context providers (e.g., an auth provider, a query-client provider) and mock system-boundary imports (the backend SDK, navigation).
   - **React hook:** `renderHook(() => useHook(...), { wrapper })` + assert on `result.current`.
   - **Service/API class:** `new Service(mockDeps).method(args)` + assert on return value. Mock only system-boundary deps, not internal collaborators.
   - **Utility function:** call with args + assert on return value.
   In a different stack, apply the same shape (render/invoke the public interface, mock only system boundaries, assert observable output) using that stack's own testing library and conventions.
4. Follow naming conventions: `describe(<exportedName>, ...)` and `it("should ...", ...)`.
5. A test whose only assertions are `toHaveBeenCalled*` matchers — or a render smoke test with no observable-behavior claim — does **not** satisfy a coverage finding. Every new/updated test must assert observable behavior through the public interface.
6. Run the project's test command against just this file (see Applicability above) to verify it passes before staging.
7. Stage with `git add <test-file>`.

**When the finding is a mock-call-only test (🔴 Must Change):**
1. Identify what observable behavior the test was meant to prove.
2. Rewrite the assertion against observable output — return value, rendered output, or hook/state transition — or move the test to the seam where that behavior is visible (see `.claude/skills/tdd/tests.md` "Wrong-seam tests").
3. If the behavior is only visible through a side-effect dependency, assert the *outcome* of the side effect via a tracking double (e.g., `expect(deps._batch.writes).toEqual([...])`), not the invocation itself.
4. Run the project's test command against just this file to verify before staging.

**When the finding is a degenerate test (🔴 Must Change for coverage):**
1. Read the existing test file to understand what it does (and doesn't) exercise.
2. Replace `expect(true).toBe(true)` or empty test bodies with real assertions that exercise the production code's public interface.
3. Run the project's test command against just this file to verify.

### Step 5: Apply 🟡 Should Change Fixes

Same process as Step 4. If a should-change fix would be destructive or controversial, flag it for user decision instead of applying blindly.

**When the finding is a missing test update for changed behavior (🟡 Should Change):**
1. Read the existing test file alongside the diff to understand the current coverage.
2. Add a new `it("should ...")` block that exercises the new/changed observable behavior through the public interface.
3. Follow the same test-pattern-by-layer guidance as in Step 4. A `toHaveBeenCalled*`-only test or a render-only smoke test does not satisfy a changed-behavior finding — assert observable output.
4. Run the project's test command against just this file (see Applicability above) to verify before staging.

**When the finding is "no existing tests" on a changed file (🟡 Should Change):**
1. This is an opportunity signal, not a mandatory fix. Present the finding to the user.
2. Offer: "This file has no test coverage. I can add a test authored red-first at the public seam that asserts observable behavior — should I?"
3. If the user accepts, follow the "missing test file" procedure from Step 4.
4. If the user declines, move on — this tier is advisory for pre-existing gaps.

### Step 6: Offer 🔵 Nitpicks

List all nitpicks. Ask: "Apply nitpicks, skip, or pick individually?" Default: skip (they're optional polish).

### Step 7: Verify with Re-Review

After all fixes are applied, re-spawn the `tech-lead-review` agent on the updated diff:
```
Agent({subagent_type: "harness-plugin:tech-lead-review", description: "Re-review after fixes applied"})
```

Compare reports:
- **All clear** (0 blockers, 0 conventions) → present verdict and done
- **New issues found** → flag them (don't auto-fix a second time — let user decide)
- **Same issues remain** → the fix approach was wrong; ask user how to proceed

### Step 8: Final Report

```
## Review & Fix Complete

**Branch:** <branch>
**Base:** <default-branch>

### Fixed (N)
- [🔴] <finding> — fixed in <file>
- [🟡] <finding> — fixed in <file>

### Acknowledged / Skipped (M)
- [🔵] <nitpick> — skipped (optional polish)

### Remaining (K)
- [🔴] <finding> — flagged for manual review (reason)

### Verdict
✅ Ready to merge — all blockers and conventions addressed.
— or —
⚠️ Proceed with caution — N items remain for manual review.
```

## Key Behaviors

| Rule | Detail |
|---|---|
| Subagent reviews | The `tech-lead-review` agent does ALL the review work — you don't re-review |
| Main agent fixes | You (main agent) apply all fixes — the subagent is read-only |
| Don't get stuck | If a fix is ambiguous, flag it and move on. Batch questions for the user. |
| Stage as you go | `git add` each file after fixing so the re-review sees the clean state |
| Verify once | One re-review pass after all fixes. Don't loop endlessly. |
| User decides on nitpicks | Never auto-apply nitpicks — they're subjective |
