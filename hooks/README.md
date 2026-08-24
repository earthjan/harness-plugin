# Claude Code hooks — harness enforcement

These hooks turn five items that used to be enforced only by prose (CLAUDE.md,
skill instructions) into mechanical checks that run at tool-call time. Wired
in `.claude/settings.json`. Session state lives in `.claude/hooks/state/`
(gitignored, one file set per `session_id`).

| # | Harness | Hook | Event / matcher |
|---|---|---|---|
| 1 | TDD "no test, no code" | `tdd-gate.sh` | `PreToolUse` on `Write\|Edit` |
| 1 | (tracks sibling-test touches for #1) | `track-touched-files.sh` | `PostToolUse` on `Write\|Edit\|Read` |
| 2 | Layer boundaries (Firebase/TanStack) | `layer-boundary-guard.sh` | `PreToolUse` on `Write\|Edit` |
| 2 | No unit tests on `pages/` | `no-page-test-guard.sh` | `PreToolUse` on `Write\|Edit` |
| 3 | Ticket registry (`INDEX.md`) regeneration | `regen-ticket-index.sh` | `PostToolUse` on `Write\|Edit` |
| 4 | Three-gate completion (tsc+lint+test) | `stop-gate-check.sh` (+ `track-gate-commands.sh`) | `Stop` (+ `PostToolUse` on `Bash`) |
| 5 | `npx expo install` only | `block-raw-package-install.sh` | `PreToolUse` on `Bash` |

## What each one does, and its limits

**tdd-gate.sh** — blocks a `Write`/`Edit` to a non-test file under
`services/app-logic/**` or `services/core/**` unless the sibling
`<name>.test.ts(x)` in the same directory has already been touched
(Read/Write/Edit) this session. It cannot tell a genuine feature/bugfix edit
from a pure refactor or a comment tweak — it gates on file identity, not on
what the edit actually does. Treat a block as "did I skip Red?", not as an
infallible verdict.

**layer-boundary-guard.sh** — greps the *new* text of a `Write`/`Edit` call
(the `content` or `new_string` field, not the whole resulting file) for an
`import`/`require` of `firebase`/`@firebase`/`@tanstack/react-query` outside
`api/`/`query/` respectively, and denies it. This is a fast, edit-time
fail-fast — the authoritative, whole-codebase version of the same rule is
the `no-restricted-imports` blocks in `eslint.config.js` (`npm run lint`).
Both exist because the hook catches the mistake before it's even written;
the lint rule catches everything else (files not touched via Claude,
existing debt, CI).

**no-page-test-guard.sh** — denies a `Write`/`Edit` that creates or edits a
`pages/**/*.test.ts(x)` file. Pages are thin wiring only and are never
tested directly — see docs/project-structure/CONTEXT.md's "Testing Guidance
Per Layer" table and `local/no-page-tests` in `eslint.config.js` (the
whole-codebase version of the same rule). The 8 pre-existing violators are
grandfathered in this hook via an explicit allowlist that mirrors
`eslint.config.js`'s `ignores` — keep the two lists in sync as files are
migrated off it.

**regen-ticket-index.sh** — runs `node docs/tickets/update-tickets-index.mjs`
whenever a `docs/tickets/*/CONTEXT.md` is written/edited. Non-blocking;
reports success/failure via `systemMessage`.

**stop-gate-check.sh** — before Claude stops, if this session wrote/edited
any `.ts`/`.tsx` file, requires `npm run tsc`, `npm run lint`, and a *full,
unfiltered* `npm test` to have each run once this session
(`track-gate-commands.sh` records that on `PostToolUse` for `Bash`). Skips
entirely for read-only/conversational sessions. Guards against an infinite
block loop via `stop_hook_active`. The "ran successfully" signal is best
effort — it trusts the Bash tool's `isError`/`is_error` response field, not
a parsed exit code or test count, so a command that exits 0 but didn't
actually do the work (e.g. `npm test -- --listTests`) isn't caught. `npm
test <file>` / `npm test -t ...` (filtered runs) are deliberately **not**
counted as satisfying the `test` gate, per CLAUDE.md.

**block-raw-package-install.sh** — denies `yarn add`, `pnpm add`, and
`npm install|i <package>` (a package argument present). Bare `npm
install`/`npm ci` (reinstalling from `package.json`/the lockfile, no new
package) is left alone.

## `npm run lint` scope (fixed)

`expo lint` only scans `src/`, `app/`, `components/` by default (see
`@expo/cli`'s `DEFAULT_INPUTS`) — this repo's lintable code lives almost
entirely under `modules/`, `functions/src/`, and `packages/`, none of which
are in that default list. `package.json`'s `lint` script now passes those
paths explicitly (`expo lint app modules functions/src
packages/eslint-rules packages/domain/src packages/defs/src`), so
`no-restricted-imports` here and the pre-existing `local/spacing-scale` /
`local/test-description-self-contained` rules actually run.

Widening the scope surfaced 9 pre-existing `react-hooks/rules-of-hooks`
errors (a hook called inside `Array.map`/after an early return — a real
"Rendered more hooks than during the previous render" crash risk, not a
lint-only nit) in `ContributionGridSection.tsx`, `PaluwaganList/index.tsx`,
and an `import/namespace` false positive in `functions/src/index.ts` (the
plugin can't resolve `firebase-functions/v1`'s subpath export; `tsc` was
already clean there) — all fixed. `layer-boundary-guard.sh` above still
exists as a fast, edit-time check ahead of the full `npm run lint` pass.

## Debugging

- `claude --debug` shows hook execution.
- State files: `.claude/hooks/state/<session_id>.*` — delete freely, hooks
  recreate them.
- If a hook doesn't fire after editing this directory, open `/hooks` once
  (or restart) — the settings watcher only watches directories that had a
  settings file when the session started.
