---
name: tech-lead-review-tests
description: Reviews test placement, coverage, assertion quality, and TDD compliance — tests authored red-first at the correct seam, not merely present. Invoke manually with /tech-lead-review-tests, standalone — for the full 4-dimension review, use /tech-lead-review instead.
disable-model-invocation: true
---

# Test Reviewer (standalone)

Thin dispatcher — spawns `agents/tech-lead-review-tests.md` on its own, outside the full `tech-lead-review` coordinator. Use this when you only want the test-quality dimension checked, not all 4. Don't duplicate the agent's own logic here; if its behavior needs to change, change the agent file, not this skill.

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
   Agent({subagent_type: "harness-plugin:tech-lead-review-tests", description: "Review <diff/scope> for test placement, coverage, assertion quality, and TDD compliance. Ticket context: <if any>"})
   ```
4. Present its findings to the user as-is.
