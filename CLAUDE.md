# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-hosted Claude Code plugin + marketplace (one repo, both roles) that packages a reusable harness — skills, review agents, gate hooks, and a ticket registry — for other projects to install. **lista-natin is the source of truth.** Improve process there first (TDD rules, ship pipelines, review agents, hooks), then port the change into this plugin, then run `/plugin marketplace update earthjan-harness` in every consuming project. Don't fork a skill's logic per-project — a real per-project difference belongs in `.claude/harness.config.json`, not a silent divergence here.

This repo has no build/lint/test commands of its own — it's config, Markdown skill/agent definitions, and shell hook scripts, not an application. "Testing a change" means installing the plugin locally in a target project and exercising the skill/hook/agent there.

## Architecture

- **`.claude-plugin/plugin.json`** + **`marketplace.json`** — plugin manifest (`harness-plugin`) registered under marketplace `earthjan-harness`. No `version` field yet (MVP, iterating fast); a local-path install pins to a commit at install time, `/plugin marketplace update` is what moves a project onto current HEAD.
- **`skills/`** — the installable behaviors: process skills (`tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `spec-builder`, `workflow-builder`, `research-workflow`), the onboarding/generator skill (`harness-init`), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). `spec-builder` is the planning half of a two-skill pipeline with `ship-ui`/`ship-non-ui` (spec first, then delivery); `research-workflow` is a fixed specialization of `workflow-builder` and depends on it being installed. No other agent has a matching skill; they're reached directly (see `agents/` below).
- **`agents/`** — the actual agent definitions (`tech-lead-review` + its four sub-checks: architecture-enforcer, code-quality, patterns, tests; `ux-builder`; `ux-reviewer`; `goal-satisfaction-reviewer`). **Agents can't be reached by slash command — only skills get those — but they're natively reachable via @-mention with the scoped name (`@harness-plugin:<name>`) and via Claude's own natural-language delegation, neither of which needs a wrapper skill.** `ship-ui`/`ship-non-ui` spawn these directly too, via their own `Agent({subagent_type: "harness-plugin:<name>"})` calls, independent of any skill (a bare, non-namespaced name errors "Agent type not found"). This plugin used to ship a thin dispatcher skill per agent for a `/harness-plugin:<name>` slash-command entry point; those were removed as redundant with @-mention — `tech-lead-review-with-fix` is the one exception, kept because it does real work beyond a dispatch. `dev-showcase-reviewer` is deliberately excluded — lista-natin-specific.
- **`hooks/`** — mechanical enforcement of what would otherwise be prose-only rules, wired via `hooks/hooks.json` (auto-loaded by the plugin) and documented in `hooks/README.md`:
  - `tdd-gate.sh` (`PreToolUse` on `Write|Edit`) — blocks editing a non-test file under a TDD-gated dir unless its sibling test file was touched first this session.
  - `track-touched-files.sh` (`PostToolUse` on `Write|Edit|Read`) — feeds the above.
  - `regen-ticket-index.sh` (`PostToolUse` on `Write|Edit`) — regenerates `docs/tickets/INDEX.md` when a ticket `CONTEXT.md` changes.
  - `stop-gate-check.sh` + `track-gate-commands.sh` (`Stop` / `PostToolUse` on `Bash`) — before stopping, requires the project's typecheck/lint/full-test commands to each have run once this session, if `.ts`/`.tsx` files were touched.
  - Session state lives in `${CLAUDE_PROJECT_DIR}/.claude/harness-state/<session_id>.*` — safe to delete, hooks recreate it.
  - Gate commands, TDD-gated dirs, and the tickets-index script path are read from the *consuming* project's own `.claude/harness.config.json` (see `hooks/scripts/lib/harness-config.sh`); defaults assume `npm` and a `services/app-logic`/`services/core` layout.
  - `hooks/examples/` (`layer-boundary-guard.sh`, `no-page-test-guard.sh`, `block-raw-package-install.sh`) are lista-natin-specific rules, kept as reference but **not** wired into `hooks.json` by default — copy one into a project's own local hooks only if that project genuinely has the equivalent rule.
- **`templates/`** — structure-only scaffolding filled in per-project by `harness-init`: `CLAUDE.md.template` (the process sections — TDD law, acceptance gates, ticket registry — are the harness's non-negotiable practice and shouldn't be rewritten per project, only the `{{PLACEHOLDER}}` commands/paths), `DESIGN.md.template`, `UX-COPY-GUIDE.md.template`, `docs/tickets/CONTEXT.md.template`, `harness.config.json.example`.
- **`scripts/update-tickets-index.mjs`** — the ticket registry generator; pure mechanism, safe to copy verbatim into any consuming project.

`DESIGN.md` and `UX-COPY-GUIDE.md` are never shipped with real content here — that's a project's own domain (brand, voice, tokens). This plugin only ships the shape plus the `harness-init` skill that fills it in per project.

## Multi-repo containers (a key architectural constraint)

Claude Code's `.claude/settings.json` — and therefore this plugin's hooks and `enabledPlugins` registration — loads **only from the exact directory a session starts in**, with no inheritance from a parent directory. If this plugin is installed at a container root (a non-git folder holding several independent git repos as subdirectories), a session started inside one of those sub-repos sees none of it: no hooks, no `harness.config.json`, nothing. Only a session started with the container itself as the working directory gets it.

For that shape, `harness-init` deliberately generates its files at the container root (not a sub-repo) so the harness docs apply broadly, but the *enforcement* (hooks, gate commands) only activates for sessions starting at that root — a sub-repo whose developers `cd` straight into it won't see any of it unless it installs the plugin itself, or a session is explicitly started from the container.

## Using this plugin in a consuming project

```bash
/plugin marketplace add ~/repos/harness-plugin        # or a git URL once pushed
/plugin install harness-plugin@earthjan-harness
/harness-plugin:harness-init <target-dir>              # onboard: writes harness.config.json, CLAUDE.md, etc.
/plugin marketplace update earthjan-harness             # pull latest into a project already installed
```

## Known MVP gaps (don't silently "fix" these — they're tracked, not oversights)

- Hook defaults assume `npm`; not yet auto-detected from `package.json`.
- No automated test coverage for the hook scripts themselves.
- `track-gate-commands.sh`'s command matching is brittle against parenthesized subshells (`(cd sub-dir && yarn test)`) and monorepo-scoped invocations (`yarn workspace X test`).
- No selective plugin enablement — a plugin install is all-or-nothing (skills + agents + hooks together). The real fix (splitting into a skills+agents plugin and a hooks-only plugin) isn't built yet.
- Every file `harness-init` generates in a consuming project is left untracked by git on purpose for now (not `git add`ed) — revisit once the multi-repo/plugin-split story above is built.
