---
name: ux-reviewer
description: Audits UI copy, tone, UX patterns, and visual design against this project's own UX copy guide and DESIGN.md, if they exist. Read-only. Invoke manually with /ux-reviewer. Use proactively after UI changes to check voice, copy rules, domain language, readability, do/don't patterns, and design-system consistency.
disable-model-invocation: true
---

# UX Reviewer (standalone)

Thin dispatcher — spawns `agents/ux-reviewer.md`. It's also spawned automatically as part of `/harness-plugin:ship-ui`'s review loop; use this skill when you want a UX/copy/design audit on its own, outside a full ship-ui run. Don't duplicate the agent's own logic here; if its behavior needs to change, change the agent file, not this skill.

## Execution

1. Determine the scope to audit: the user's specified files/screens, or if none given, the current branch's diff against the default branch (`git symbolic-ref refs/remotes/origin/HEAD`, then `git diff <default-branch>...HEAD`) or the staged diff (`git diff --cached`) — ask if ambiguous.
2. If the work maps to a ticket (a `docs/tickets/<id>/` directory exists), read `docs/tickets/INDEX.md` to locate it, then read only that ticket's `CONTEXT.md` frontmatter.
3. Spawn the agent:
   ```
   Agent({subagent_type: "harness-plugin:ux-reviewer", description: "Audit UX copy, tone, and visual design on <scope>. Ticket context: <if any>"})
   ```
4. Present its findings to the user as-is.
