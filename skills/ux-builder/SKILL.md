---
name: ux-builder
description: Creates new screens or improves existing ones. Loads this project's UX copy guide and architecture docs. Invoke manually with /ux-builder for UI/UX implementation tasks — new screens, redesigns, copy improvements, or any user-facing UI code — outside a full /harness-plugin:ship-ui run.
disable-model-invocation: true
---

# UX Builder (standalone)

Thin dispatcher — spawns `agents/ux-builder.md`. `/harness-plugin:ship-ui` implements as a senior front-end engineer directly rather than spawning this agent, so use this skill when you want the same UI-building process on a smaller, standalone task without the full ship-ui pipeline (PLAN.md, review loop, walkthrough). Don't duplicate the agent's own logic here; if its behavior needs to change, change the agent file, not this skill.

## Execution

1. Pass the user's request through as given — the task description, any spec/mock/wireframe file they pointed at, and any target directory or existing screen to modify.
2. If the work maps to a ticket (a `docs/tickets/<id>/` directory exists), read `docs/tickets/INDEX.md` to locate it, then read only that ticket's `CONTEXT.md` frontmatter, and include it in the brief.
3. Spawn the agent:
   ```
   Agent({subagent_type: "harness-plugin:ux-builder", description: "<the user's request, verbatim or lightly summarized>. Ticket context: <if any>"})
   ```
4. Relay its output/changes to the user.
