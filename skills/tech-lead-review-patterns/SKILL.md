---
name: tech-lead-review-patterns
description: Reviews changes against this project's own established code patterns — domain language, code-placement conventions, OOP conventions, copy/string extraction, component extraction. Invoke manually with /tech-lead-review-patterns, standalone — for the full 4-dimension review, use /tech-lead-review instead.
disable-model-invocation: true
---

# Pattern Reviewer (standalone)

Thin dispatcher — spawns `agents/tech-lead-review-patterns.md` on its own, outside the full `tech-lead-review` coordinator. Use this when you only want the patterns/conventions dimension checked, not all 4. Don't duplicate the agent's own logic here; if its behavior needs to change, change the agent file, not this skill.

## Execution

1. Discover the default branch and collect the diff to review:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD
   git diff <default-branch>...HEAD
   ```
   Or, if the user specified a different scope (staged changes, a specific PR, a specific file set), use that instead.
2. If the branch references a ticket (a `docs/tickets/<id>/` directory exists), read `docs/tickets/INDEX.md` to locate it, then read only that ticket's `CONTEXT.md` frontmatter.
3. Spawn the agent:
   ```
   Agent({subagent_type: "harness-plugin:tech-lead-review-patterns", description: "Review <diff/scope> for domain language, code-placement, OOP, and pattern conventions. Ticket context: <if any>"})
   ```
4. Present its findings to the user as-is.
