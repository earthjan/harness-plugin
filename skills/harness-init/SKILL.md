---
name: harness-init
description: Bootstrap or upgrade a project's Claude Code harness to match the harness-plugin standard (CLAUDE.md, DESIGN.md, UX-COPY-GUIDE.md, docs/tickets registry, harness.config.json). Use when installing this plugin into a new or existing project for the first time, or when reconciling a project's own drifted-from-standard harness back onto the plugin's source-of-truth practice.
argument-hint: "Target directory to generate the harness files into (optional — ask if not given, default to the current directory)"
---

# Harness Init

This skill turns the process this plugin ships (TDD law, ship pipelines, tech-lead review, ticket registry, gate hooks) into files that actually exist for the target project — without copying another project's domain content into it. Templates in `templates/` are structure only; every `{{PLACEHOLDER}}` gets replaced with this project's own facts, never another project's.

lista-natin is the source-of-truth harness this plugin was extracted from. When this project's own local docs conflict with what this skill produces, prefer the plugin's process sections (TDD, acceptance gates, ticket registry) and flag the conflict to the user rather than silently picking one.

## Steps

0. **Determine the target directory.** Use whatever directory the user passed as this skill's argument. If none was given, ask: "Which directory should these harness files go into?" — default to the current working directory only if the user confirms that's right. This matters most for a multi-repo container (several independent git repos living as subdirectories under one non-git parent, e.g. a per-org `repos/<company>/` folder) — in that shape, point this at the container root rather than any one sub-repo, so the harness files apply broadly without living inside a specific team's git history. Everything below reads/writes relative to this target directory, referred to as `<target-dir>`.

   **MVP note (revisit later):** for now, treat every file this skill generates (`CLAUDE.md`, `DESIGN.md`, `UX-COPY-GUIDE.md`, `docs/tickets/`, `.claude/harness.config.json`) as intentionally **not git-tracked** — don't `git add`/commit them as part of this skill, regardless of whether `<target-dir>` happens to be inside a git repo. This sidesteps deciding, per sub-repo, whose git history these shared files belong in. If `<target-dir>` is itself (or is inside) a git repo, add a note reminding the user to gitignore them if they want that enforced rather than just conventionally untracked. Revisit this once the plugin's own multi-repo story (see the top-level README) is designed properly — this is a placeholder decision, not a permanent one.

1. **Survey what already exists** in `<target-dir>`. Check for: `CLAUDE.md`, `DESIGN.md`, `UX-COPY-GUIDE.md`, `docs/tickets/`, `.claude/skills/`, `.claude/agents/`, `.claude/settings.json` hooks, `package.json` (package manager + script names), and any existing architecture/coding-guideline docs. Don't assume — read them.

2. **Detect the gate commands.** From `<target-dir>/package.json` scripts (or the project's actual command history if scripts aren't standard names), determine the real typecheck/lint/test commands. Default assumption is `npm run tsc` / `npm run lint` / `npm test` — override per what's actually there (e.g. `yarn tsc`, `yarn lint`, `yarn test`). If `<target-dir>` has no single `package.json` (a multi-repo container), ask which sub-repo's commands should represent the gate, or leave gate commands as the bare default and note that per-sub-repo overrides may be needed later.

3. **Write `<target-dir>/.claude/harness.config.json`** (see `templates/harness.config.json.example`) with the detected gate commands and, if the project has a `services/app-logic` + `services/core` split, the TDD-gated dirs — otherwise ask the user what the equivalent testable-unit boundary is for this project, or leave `tddGatedDirs` empty if none applies yet. Also add `.claude/harness-state/` to `<target-dir>/.gitignore` if it isn't already covered — every hook writes session-scoped log/marker files there, and left untracked-but-ungitignored they show up as noise in `git status`.

4. **Generate/update `<target-dir>/CLAUDE.md`** from `templates/CLAUDE.md.template`. Keep every section marked PROCESS verbatim (TDD law, acceptance criteria structure, ticket registry harness) — these are the plugin's non-negotiable practice, not per-project choices. Fill every `{{PLACEHOLDER}}` from what step 1 found; where nothing exists yet, ask the user rather than inventing architecture. If a `CLAUDE.md` already exists at `<target-dir>`, diff against the template and propose changes — don't silently overwrite content the user wrote by hand.

5. **Generate/update `<target-dir>/DESIGN.md` and `<target-dir>/UX-COPY-GUIDE.md`**, but only if the project has a user-facing UI. Use `templates/DESIGN.md.template` / `templates/UX-COPY-GUIDE.md.template` as the section skeleton. Fill content by asking the user (brand colors, voice, existing component library) and by reading whatever UI code/design tokens already exist — never carry over lista-natin's actual MD3 values or copy voice; those are lista-natin's domain, not this project's.

6. **Scaffold the ticket registry** at `<target-dir>/docs/tickets/`. Copy `scripts/update-tickets-index.mjs` from the plugin into `<target-dir>/docs/tickets/update-tickets-index.mjs` (this is pure mechanism, safe to copy verbatim). Create `<target-dir>/docs/tickets/INDEX.md` by running it. For any ticket directories that already exist without a `CONTEXT.md`, use `templates/docs/tickets/CONTEXT.md.template` and `node docs/tickets/update-tickets-index.mjs --init` if present, or hand-scaffold per the template's frontmatter shape.

7. **Reconcile local skills/agents that overlap with the plugin.** If `<target-dir>` has its own `.claude/skills/<name>` or `.claude/agents/<name>.md` that duplicate something this plugin now provides (e.g. a project-local `ship-non-ui` or `tech-lead-review`), tell the user which ones collide and confirm before removing the local copy — the plugin version wins by default since lista-natin is the source of truth, but don't delete project-specific customizations without a look.

8. **Flag any plugin content that still needs a project-specific pass.** Even genericized, a few plugin components carry an explicit "adapt before first real use" note in their own file (`browser-verify` — dev server URL/viewport/auth accounts; `wireframe-html` — the scaffold script fallback; `testable-app-logic` — non-React idiom mapping). Check each one's own applicability/fallback note and tell the user which apply to this project and what, concretely, still needs filling in before that skill is trustworthy here — don't let this pass silently just because the plugin loaded without error.

9. **Flag the plugin's own installation-scope limits.** If `<target-dir>` is a multi-repo container (several independent git repos as subdirectories) rather than a single git repo, tell the user explicitly: `.claude/settings.json` in Claude Code does not inherit from a parent directory — a session started inside one of the sub-repos will not see `<target-dir>`'s plugin install, hooks, or `harness.config.json` at all, only a session started with `<target-dir>` itself as the working directory will. This is a real, current limitation (see the top-level README), not a hypothetical — say so plainly rather than letting the user assume broader coverage than what's actually wired up.

10. **Report a summary**, not a wall of diffs: what was created, what was updated, what was left for the user to fill in by hand, any collisions found in step 7, any adapt-before-use flags from step 8, and the scope-limit note from step 9 if it applied.

## What this skill does NOT do

- It does not invent architecture, domain language, or brand voice — those come from the user or from what's already in the codebase.
- It does not overwrite hand-written project docs without showing the diff first.
- It does not port lista-natin's actual DESIGN.md/UX-COPY-GUIDE.md content — those files are lista-natin's own domain, not a shared default.
- It does not commit any file it generates (see step 0's MVP note) — that decision is left to the user.
