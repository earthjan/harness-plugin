---
name: harness-init
description: Bootstrap or upgrade a project's Claude Code harness to match the harness-plugin standard (CLAUDE.md, DESIGN.md, UX-COPY-GUIDE.md, docs/tickets registry, harness.config.json). Use when installing this plugin into a new or existing project for the first time, or when reconciling a project's own drifted-from-standard harness back onto the plugin's source-of-truth practice.
---

# Harness Init

This skill turns the process this plugin ships (TDD law, ship pipelines, tech-lead review, ticket registry, gate hooks) into files that actually exist in the *current* project — without copying another project's domain content into it. Templates in `templates/` are structure only; every `{{PLACEHOLDER}}` gets replaced with this project's own facts, never another project's.

lista-natin is the source-of-truth harness this plugin was extracted from. When this project's own local docs conflict with what this skill produces, prefer the plugin's process sections (TDD, acceptance gates, ticket registry) and flag the conflict to the user rather than silently picking one.

## Steps

1. **Survey what already exists.** Check for: `CLAUDE.md`, `DESIGN.md`, `UX-COPY-GUIDE.md`, `docs/tickets/`, `.claude/skills/`, `.claude/agents/`, `.claude/settings.json` hooks, `package.json` (package manager + script names), and any existing architecture/coding-guideline docs. Don't assume — read them.

2. **Detect the gate commands.** From `package.json` scripts (or the project's actual command history if scripts aren't standard names), determine the real typecheck/lint/test commands. Default assumption is `npm run tsc` / `npm run lint` / `npm test` — override per what's actually there (e.g. `yarn tsc`, `yarn lint`, `yarn test`).

3. **Write `.claude/harness.config.json`** (see `templates/harness.config.json.example`) with the detected gate commands and, if the project has a `services/app-logic` + `services/core` split, the TDD-gated dirs — otherwise ask the user what the equivalent testable-unit boundary is for this project, or leave `tddGatedDirs` empty if none applies yet.

4. **Generate/update `CLAUDE.md`** from `templates/CLAUDE.md.template`. Keep every section marked PROCESS verbatim (TDD law, acceptance criteria structure, ticket registry harness) — these are the plugin's non-negotiable practice, not per-project choices. Fill every `{{PLACEHOLDER}}` from what step 1 found; where nothing exists yet, ask the user rather than inventing architecture. If a project `CLAUDE.md` already exists, diff against the template and propose changes — don't silently overwrite content the user wrote by hand.

5. **Generate/update `DESIGN.md` and `UX-COPY-GUIDE.md`**, but only if the project has a user-facing UI. Use `templates/DESIGN.md.template` / `templates/UX-COPY-GUIDE.md.template` as the section skeleton. Fill content by asking the user (brand colors, voice, existing component library) and by reading whatever UI code/design tokens already exist — never carry over lista-natin's actual MD3 values or copy voice; those are lista-natin's domain, not this project's.

6. **Scaffold the ticket registry.** Copy `scripts/update-tickets-index.mjs` from the plugin into `docs/tickets/update-tickets-index.mjs` in the project (this is pure mechanism, safe to copy verbatim). Create `docs/tickets/INDEX.md` by running it. For any ticket directories that already exist without a `CONTEXT.md`, use `templates/docs/tickets/CONTEXT.md.template` and `node docs/tickets/update-tickets-index.mjs --init` if present, or hand-scaffold per the template's frontmatter shape.

7. **Reconcile local skills/agents that overlap with the plugin.** If the project has its own `.claude/skills/<name>` or `.claude/agents/<name>.md` that duplicate something this plugin now provides (e.g. a project-local `ship-non-ui` or `tech-lead-review`), tell the user which ones collide and confirm before removing the local copy — the plugin version wins by default since lista-natin is the source of truth, but don't delete project-specific customizations without a look.

8. **Report a summary**, not a wall of diffs: what was created, what was updated, what was left for the user to fill in by hand, and any collisions found in step 7 that still need a decision.

## What this skill does NOT do

- It does not invent architecture, domain language, or brand voice — those come from the user or from what's already in the codebase.
- It does not overwrite hand-written project docs without showing the diff first.
- It does not port lista-natin's actual DESIGN.md/UX-COPY-GUIDE.md content — those files are lista-natin's own domain, not a shared default.
