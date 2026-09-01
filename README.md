# harness-plugin

Reusable Claude Code harness, extracted from [lista-natin](https://github.com/) — the source-of-truth project for this practice. Ships as a self-hosted plugin + marketplace (one repo, both roles).

## What's in here

- **`skills/`** — `tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `spec-builder`, `workflow-builder`, `research-workflow`, `harness-init` (the onboarding/generator skill — see below), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). `spec-builder` is the planning half of a two-skill pipeline with `ship-ui`/`ship-non-ui`; `research-workflow` specializes `workflow-builder` and requires it installed alongside it. No other agent has a matching skill; they're reached directly (see `agents/` below).
- **`agents/`** — `tech-lead-review*` (architecture-enforcer, code-quality, patterns, tests), `ux-builder`, `ux-reviewer`, `goal-satisfaction-reviewer`, plus the phase agents a skill spawns rather than a user reaching for: `spec-ac-writer`/`spec-ac-reviewer` (spec-builder Phase 3.6), `spec-tech-lead-scout`/`spec-tech-lead-judge` (Phase 3.7 — the only pass that sees a finished spec with the codebase open), `qa-test-planner`/`qa-test-plan-reviewer` (ship-ui manual QA). (`dev-showcase-reviewer` deliberately excluded — lista-natin-specific dev-showcase feature.) **Agents can't be reached by slash command — only skills get those — but they're natively reachable via @-mention with the scoped name (`@harness-plugin:<name>`) and via Claude's own natural-language delegation, neither of which needs a wrapper skill.** `ship-ui`/`ship-non-ui` spawn these directly too, via their own `Agent({subagent_type: "harness-plugin:<name>"})` calls, independent of any skill (a bare, non-namespaced name errors "Agent type not found"). This plugin used to ship a thin dispatcher skill per agent for a `/harness-plugin:<name>` slash-command entry point; those were removed as redundant with @-mention — `tech-lead-review-with-fix` is the one exception, kept because it does real work beyond a dispatch.
- **`hooks/`** — gate/TDD/ticket-registry hooks, config-driven (see `.claude/harness.config.json` below). `hooks/examples/` holds three hooks kept as reference but **not** wired into the default `hooks.json`, because each encodes a rule specific to lista-natin rather than something every project shares — copy the relevant one into a project's own local hooks only if that project genuinely has the same rule: `layer-boundary-guard.sh` and `no-page-test-guard.sh` (lista-natin's React-Native layer-model enforcement — assume a folder layout, `api/`/`query/`/`pages/`, other projects won't share) and `block-raw-package-install.sh` (lista-natin's Expo-only "use `npx expo install`, not raw npm/yarn/pnpm" rule — would incorrectly block ordinary installs in a non-Expo project).
- **`scripts/update-tickets-index.mjs`** — the ticket registry generator, pure mechanism, safe to copy verbatim into any project.
- **`templates/`** — `CLAUDE.md.template`, `DESIGN.md.template`, `UX-COPY-GUIDE.md.template`, `docs/tickets/CONTEXT.md.template`, `harness.config.json.example`. Structure only — every project fills its own content in.

## What's NOT in here (by design)

`DESIGN.md` and `UX-COPY-GUIDE.md` are never shipped with real content — those are a project's own domain (brand, voice, tokens). The plugin ships the *shape* (`templates/*.template`) and a generator skill (`harness-init`) that fills it in per-project. Same for `CLAUDE.md`'s architecture/domain sections.

## Source of truth

lista-natin is the canonical harness. Improve process there first (TDD rules, ship pipelines, review agents, hooks), then port the change into this plugin, then run `/plugin marketplace update earthjan-harness` in every consuming project. Don't fork a skill's logic per-project — if a project genuinely needs different behavior, that's a config knob (`.claude/harness.config.json`) or a signal the plugin's abstraction is wrong, not a reason to diverge silently.

## Using this in a project

```bash
/plugin marketplace add ~/repos/harness-plugin        # or a git URL once pushed
/plugin install harness-plugin@earthjan-harness
```

Then invoke the onboarding skill, telling it which directory to generate into:

```
/harness-plugin:harness-init <target-dir>
```

It surveys `<target-dir>`, writes `<target-dir>/.claude/harness.config.json` (gate commands, TDD-gated dirs), generates/updates `<target-dir>/CLAUDE.md` from the template, and scaffolds `DESIGN.md` / `UX-COPY-GUIDE.md` / `docs/tickets/` there if they don't already exist — see `skills/harness-init/SKILL.md` for exactly what it does and doesn't do. **MVP tradeoff:** every file it generates is left untracked by git on purpose (not `git add`ed by the skill) — see harness-init's step 0 and "Multi-repo containers" below.

### Multi-repo containers (e.g. several independent git repos under one non-git parent folder)

Claude Code's `.claude/settings.json` — and therefore this plugin's hooks, and its `enabledPlugins` registration — loads **only from the exact directory a session starts in**, with no inheritance from a parent directory. If this plugin is installed at a container root (a folder holding several independent git repos as subdirectories, itself not a git repo), a session started inside one of those sub-repos will not see the container's install at all: no hooks, no `harness.config.json`, nothing. Only a session started with the container itself as the working directory gets it.

For that shape, `harness-init` generates its files at the container root by design (point it there, not at a sub-repo — see its step 0) so the harness docs apply broadly rather than living inside one team's git history, but be aware the *enforcement* (hooks, gate commands) currently only activates for sessions that start at that root. A sub-repo whose developers always `cd` straight into their own repo won't see any of it unless that sub-repo installs the plugin itself, or a session is explicitly started from the container — the plugin-split approach below is still the more complete fix, just not built yet.

## Updating

```bash
/plugin marketplace update earthjan-harness
```

No `version` field is set on `plugin.json` yet (MVP — iterating fast). A local-path install already pins to a specific commit at install time (`claude plugin list` shows a fixed short hash per install) — it's `/plugin marketplace update earthjan-harness` that moves a project onto whatever the plugin repo's HEAD is now, not every session. Add semver pinning once this stabilizes and multiple projects depend on it not moving under them mid-task.

## Known MVP gaps (improve later, not blocking)

- Hook defaults assume `npm`; `.claude/harness.config.json` overrides but isn't auto-detected yet — `harness-init` should eventually read `package.json` and write it automatically rather than asking.
- No automated test coverage for the hook scripts themselves.
- `track-gate-commands.sh`'s command-matching is brittle against parenthesized subshells (`(cd sub-dir && yarn test)`) and monorepo-scoped invocations (`yarn workspace X test`) — a real risk in a multi-repo container project, not just a theoretical one. Not blocking for MVP; a config option to match a command by regex instead of exact string would fix it.
- No selective plugin enablement — a plugin install is all-or-nothing (skills + agents + hooks together) at whatever scope (user/project/local) you install it at. For a multi-repo container where shared tools should reach every sub-repo but hook enforcement should stay opt-in per sub-repo, the real fix is splitting this into two plugins (skills+agents only, installed at user scope; hooks only, installed per sub-repo by whoever owns it) — not done yet, tracked here rather than solved with a workaround.
- Generated harness files (`CLAUDE.md`, `DESIGN.md`, `UX-COPY-GUIDE.md`, `docs/tickets/`, `.claude/harness.config.json`) are left untracked by git on purpose for now — `harness-init` doesn't commit them. Revisit once the multi-repo/plugin-split story above is actually built; right now this is a placeholder choice, not a permanent one.
