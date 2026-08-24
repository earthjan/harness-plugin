---
name: goal-satisfaction-reviewer
description: Verifies that delivered implementation satisfies the acceptance criteria in a plan file. Invoke manually with /goal-satisfaction-reviewer. Use after quality reviews pass to confirm spec compliance before walkthrough, standalone — outside a full /harness-plugin:ship-ui or /harness-plugin:ship-non-ui run.
disable-model-invocation: true
---

# Goal-Satisfaction Reviewer (standalone)

Thin dispatcher — spawns `agents/goal-satisfaction-reviewer.md`. It's also spawned automatically as the last review step in `/harness-plugin:ship-ui` and `/harness-plugin:ship-non-ui`; use this skill when you want a spec-compliance check on its own, outside a full ship run. Don't duplicate the agent's own logic here; if its behavior needs to change, change the agent file, not this skill.

## Execution

1. Locate the plan file — ask the user if not obvious (commonly `PLAN.md`/`PLAN-NONUI.md` at the project root or a delivery working directory).
2. Collect the diff to check against it: staged changes (`git diff --cached`) by default, or whatever scope the user specifies.
3. Spawn the agent:
   ```
   Agent({subagent_type: "harness-plugin:goal-satisfaction-reviewer", description: "Verify the delivered implementation satisfies the acceptance criteria in <plan file>."})
   ```
4. Present its findings to the user as-is.
