# Ticket — publish `spec-builder`

Run this **third**, after `01-workflow-builder.md` and `02-research-workflow.md`.

## 1. Copy the skill

```bash
mkdir -p /Users/earthjan/repos/harness-plugin/skills/spec-builder
cp /Users/earthjan/.claude/skills/spec-builder/SKILL.md \
   /Users/earthjan/repos/harness-plugin/skills/spec-builder/SKILL.md
cp -r /Users/earthjan/.claude/skills/spec-builder/references \
      /Users/earthjan/repos/harness-plugin/skills/spec-builder/references
```

Deliberately **not** copied:
- `NOTES.md` — the author's own dev-journal from benchmarking this skill; not skill content.
- `evals/` — same open decision as the other two skills (see `00-overview.md`). Add
  `cp -r /Users/earthjan/.claude/skills/spec-builder/evals /Users/earthjan/repos/harness-plugin/skills/spec-builder/evals`
  here if you opted in.

## 2. No content edits needed

`SKILL.md` ends with its own explicit portability note: *"This skill is written to work in any
project, not just this one — it reads whatever project it's currently running in's own CLAUDE.md
and architecture docs at runtime... rather than assuming any specific folder names."* Verified
against the actual dependencies it names, including a grep for any leftover personal-machine path
(none found — clean):

- `ship-ui` / `ship-non-ui` hand-off — ✅ both already ship in this plugin's `skills/`.
- `research-workflow` (heavy-research path, Phase 1) — ✅ published in `02-research-workflow.md`.
- `docs/tickets/<id>/CONTEXT.md`, `docs/tickets/INDEX.md`, `node docs/tickets/update-tickets-
  index.mjs` — ✅ this is exactly where `harness-init` scaffolds the ticket registry in a
  consuming project (`skills/harness-init/SKILL.md:29`: *"Copy `scripts/update-tickets-index.mjs`
  from the plugin into `<target-dir>/docs/tickets/update-tickets-index.mjs`"*). Same path, no
  mismatch.
- `argument-hint` frontmatter field — ✅ already used by `instructions-readme-drift-check`,
  `regression-sweep`, `harness-init` in this plugin; not a new frontmatter shape.
- `disable-model-invocation: true` frontmatter field — this one is genuinely new to this plugin
  (confirmed: no other skill here uses it — `grep -rn "disable-model-invocation" skills/` turns up
  nothing before this port). Still fine to ship: it's a documented, supported Claude Code
  frontmatter field, and `spec-builder`'s own description explains why it needs it ("creates a
  real ticket and can spend a real research pass" — shouldn't fire from casual conversation). Just
  flagging it as new, not claiming it's already-precedented.

## 3. Verify

```bash
cd /Users/earthjan/repos/harness-plugin
ls skills/spec-builder/
# expect: SKILL.md  references/   (no NOTES.md, no evals/ unless opted in)

grep -rn "~/.claude/skills\|/Users/earthjan" skills/spec-builder
# expect: no output
```
