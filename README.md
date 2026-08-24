# harness-plugin

Reusable Claude Code harness, extracted from [lista-natin](https://github.com/) — the source-of-truth project for this practice. Ships as a self-hosted plugin + marketplace (one repo, both roles).

## What's in here

- **`skills/`** — `tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `tech-lead-review`, `tech-lead-review-with-fix`, `instructions-readme-drift-check`, and `harness-init` (the onboarding/generator skill — see below).
- **`agents/`** — `tech-lead-review*` (architecture-enforcer, code-quality, patterns, tests), `ux-builder`, `ux-reviewer`, `goal-satisfaction-reviewer`. (`dev-showcase-reviewer` deliberately excluded — lista-natin-specific dev-showcase feature.)
- **`hooks/`** — gate/TDD/ticket-registry hooks, config-driven (see `.claude/harness.config.json` below). `hooks/examples/` holds `layer-boundary-guard.sh` and `no-page-test-guard.sh` — lista-natin's own React-Native layer-model enforcement, kept as reference but **not** wired into the default `hooks.json` since they assume a folder layout (`api/`, `query/`, `pages/`) other projects won't share. Copy into a project's own local hooks if that project has the same layer model.
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

Then, in that project, invoke the onboarding skill:

```
/harness-plugin:harness-init
```

It surveys the project, writes `.claude/harness.config.json` (gate commands, TDD-gated dirs), generates/updates `CLAUDE.md` from the template, and scaffolds `DESIGN.md` / `UX-COPY-GUIDE.md` / `docs/tickets/` if they don't already exist — see `skills/harness-init/SKILL.md` for exactly what it does and doesn't do.

## Updating

```bash
/plugin marketplace update earthjan-harness
```

No `version` field is set on `plugin.json` yet (MVP — iterating fast); consumers track the latest git state. Add semver pinning once this stabilizes and multiple projects depend on it not moving under them mid-task.

## Known MVP gaps (improve later, not blocking)

- Hook defaults assume `npm`; `.claude/harness.config.json` overrides but isn't auto-detected yet — `harness-init` should eventually read `package.json` and write it automatically rather than asking.
- No automated test coverage for the hook scripts themselves.
- `browser-verify` and `ship-ui`/`ship-non-ui` still reference lista-natin's own doc paths in prose in a few places — flagged for cleanup as each gets used on a second project and the seams that don't generalize become visible.
