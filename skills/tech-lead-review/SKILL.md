---
name: tech-lead-review
description: Code review at tech-lead depth against this project's documented architecture, domain language, coding guidelines, and guardrails. Invoke manually with /tech-lead-review.
disable-model-invocation: true
---

# Tech Lead Review

This is the manual entry point (`/tech-lead-review`) for the same coordinator logic as the `tech-lead-review` agent (`agents/tech-lead-review.md`). Don't duplicate that logic here — spawn the agent and relay its report. Keeping one implementation means the review depth, doc-discovery behavior, and gate-command handling can't drift between the two invocation paths.

## Execution

1. Discover the default branch and collect git context (current branch, commit messages, full diff) — the agent needs this to scope its review, but you gather it here so the dispatch is self-contained:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD
   ```
2. If the branch references a ticket (a `docs/tickets/<id>/` directory exists), read `docs/tickets/INDEX.md` to locate it, then read only that ticket's `CONTEXT.md` frontmatter — don't read every file in the ticket dir.
3. Spawn the `tech-lead-review` agent with the diff and any ticket context:
   ```
   Agent({subagent_type: "tech-lead-review", description: "Review branch diff against default branch. Ticket context: <title/description/state, if any>"})
   ```
   The agent handles everything else: discovering this project's own doc list from its `CLAUDE.md`, dispatching the 4 specialized sub-agents, reading gate commands from `.claude/harness.config.json`, synthesizing findings, and rendering the report. See `agents/tech-lead-review.md` for that full flow — it's the single source of truth for the coordinator's behavior.
4. Present the agent's report to the user as-is. Don't re-review or second-guess it.

## Hard Principles

- **This skill is a thin dispatcher, not a second implementation.** If the coordinator's behavior needs to change (doc discovery, gate commands, report format, sub-agent roster), change `agents/tech-lead-review.md` — this file should only ever need git-context collection and the dispatch call.
- **This skill stands alone otherwise.** Don't suggest running other skills after presenting the report.
