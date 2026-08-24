# Claude Code hooks — harness enforcement

These hooks turn parts of the harness that would otherwise be enforced only
by prose (CLAUDE.md, skill instructions) into mechanical checks that run at
tool-call time. Wired via `hooks/hooks.json` (auto-loaded by the plugin —
see `.claude-plugin/plugin.json`). Session state lives in
`${CLAUDE_PROJECT_DIR}/.claude/harness-state/` (add this to the consuming
project's `.gitignore`; `harness-init` does this — see
`skills/harness-init/SKILL.md` step 3), one file set per `session_id`.

Gate commands, TDD-gated dirs, and the tickets-index script path are all
read from the consuming project's own `.claude/harness.config.json` (see
`hooks/scripts/lib/harness-config.sh`) — defaults assume `npm` and a
`services/app-logic`/`services/core` layout; override per project.

## Wired by default (`hooks/hooks.json`)

| # | Harness | Hook | Event / matcher |
|---|---|---|---|
| 1 | TDD "no test, no code" | `tdd-gate.sh` | `PreToolUse` on `Write\|Edit` |
| 1 | (tracks sibling-test touches for #1) | `track-touched-files.sh` | `PostToolUse` on `Write\|Edit\|Read` |
| 2 | Ticket registry (`INDEX.md`) regeneration | `regen-ticket-index.sh` | `PostToolUse` on `Write\|Edit` |
| 3 | Three-gate completion (typecheck+lint+test) | `stop-gate-check.sh` (+ `track-gate-commands.sh`) | `Stop` (+ `PostToolUse` on `Bash`) |

## What each one does, and its limits

**tdd-gate.sh** — blocks a `Write`/`Edit` to a non-test file under any of
`$HARNESS_TDD_GATED_DIRS` (default: `services/app-logic/**`,
`services/core/**`) unless the sibling `<name>.test.ts(x)` in the same
directory has already been touched (Read/Write/Edit) this session. It
cannot tell a genuine feature/bugfix edit from a pure refactor or a comment
tweak — it gates on file identity, not on what the edit actually does. Treat
a block as "did I skip Red?", not as an infallible verdict.

**regen-ticket-index.sh** — runs `node $HARNESS_TICKETS_INDEX_SCRIPT`
(default `docs/tickets/update-tickets-index.mjs`) whenever a
`docs/tickets/*/CONTEXT.md` is written/edited. Non-blocking; reports
success/failure via `systemMessage`.

**stop-gate-check.sh** — before Claude stops, if this session wrote/edited
any `.ts`/`.tsx` file, requires the configured typecheck, lint, and a
*full, unfiltered* test command to have each run once this session
(`track-gate-commands.sh` records that on `PostToolUse` for `Bash`). Skips
entirely for read-only/conversational sessions. Guards against an infinite
block loop via `stop_hook_active`. The "ran successfully" signal is best
effort — it trusts the Bash tool's `isError`/`is_error` response field, not
a parsed exit code or test count, so a command that exits 0 but didn't
actually do the work isn't caught. A filtered/partial test run is
deliberately **not** counted as satisfying the test gate.

**track-gate-commands.sh** — exact-matches a Bash command's segments
(split on `&&`/`||`/`;`/`|`, redirections stripped) against the configured
gate commands. Known limit: it does not unwrap parenthesized subshells
(`(cd sub-dir && yarn test)`) or monorepo-scoped invocations (`yarn
workspace X test`) — those silently never mark the gate satisfied, so
`stop-gate-check.sh` keeps blocking even after the real command ran. Not
fixed for MVP; see the top-level README's "Known MVP gaps."

## `hooks/examples/` — not wired by default

These encode a rule specific to lista-natin, not something every consuming
project shares. Copy one into a project's own local hooks only if that
project genuinely has the equivalent rule — see each file's own header
comment for what it assumes and why it isn't a safe default:

- `layer-boundary-guard.sh` — Firebase/TanStack-Query import boundaries,
  assumes an `api/`/`query/` folder split.
- `no-page-test-guard.sh` — no unit tests directly on a `pages/` layer,
  assumes that exact layer exists.
- `block-raw-package-install.sh` — "use `npx expo install`, not raw
  npm/yarn/pnpm add," assumes an Expo/React Native project.

## Debugging

- `claude --debug` shows hook execution.
- State files: `${CLAUDE_PROJECT_DIR}/.claude/harness-state/<session_id>.*`
  — delete freely, hooks recreate them.
- If a hook doesn't fire after editing this directory, open `/hooks` once
  (or restart) — the settings watcher only watches directories that had a
  settings file when the session started.
