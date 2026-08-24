---
name: harness-hooks-init
description: Vendor harness-plugin's gate/TDD/ticket-registry hooks — as real, git-trackable files — into a target project's own .claude/hooks/ and .claude/settings.json, instead of relying on the plugin install to deliver them. Use when a project needs these hooks but won't reliably get them from the plugin's own installation scope — most commonly a sub-repo inside a multi-repo container, where a session started at the sub-repo never sees a container-root plugin install at all.
argument-hint: "Target directory to vendor the hooks into (optional — ask if not given, default to the current directory)"
---

# Harness Hooks Init

This skill copies hook scripts **verbatim** into a project and wires them into that project's own `.claude/settings.json`, rather than the project depending on harness-plugin's own hook delivery (`hooks/hooks.json`, auto-loaded when the plugin is installed and the session starts at the right directory).

## Why this exists, and when to use it instead of (or alongside) installing the plugin

The plugin's own hooks only activate for a session started with the plugin's installed directory as the working directory — Claude Code's `.claude/settings.json` does not inherit from a parent directory (see the top-level README's "Multi-repo containers" section). For a single-repo project, installing the plugin is enough. For a multi-repo container (several independent git repos as subdirectories under one non-git parent), a sub-repo whose developers `cd` straight into it will never see the container's plugin install — this skill is how that sub-repo gets the hooks anyway, as its own local copy.

**Tradeoff, stated plainly:** a vendored copy is not a live reference. A future improvement to `hooks/scripts/*.sh` in this plugin does not automatically reach a project that vendored them — that project needs this skill re-run to pick up the change. This is a deliberate choice (like `shadcn/ui`'s vendoring model), not an oversight — vendoring trades auto-update for the hooks actually running somewhere the plugin install can't reach.

**Don't vendor into a project that already receives these hooks live** — check whether `.claude/settings.json` at the target directory already has `harness-plugin@<marketplace-name>` in `enabledPlugins` at `true`. If so, vendoring on top would make every hook fire twice per matching tool call. This skill is for reaching a directory the plugin's own install *doesn't* cover, not for duplicating coverage where it already exists.

## Steps

1. **Determine the target directory**, same convention as `harness-init`: use the argument if given, otherwise ask. Referred to as `<target-dir>` below.

2. **Check for double-coverage.** Read `<target-dir>/.claude/settings.json` if it exists. If `enabledPlugins` already has a `harness-plugin@*` entry set to `true`, stop and tell the user this directory already gets the hooks live via the plugin — vendoring here would double-fire them. Ask whether they still want to proceed (e.g. they're about to uninstall the plugin here and want the hooks to keep working) before continuing.

3. **Copy the hook scripts verbatim.** From this plugin's own `hooks/scripts/` directory, copy every `.sh` file and the `lib/harness-config.sh` subdirectory into `<target-dir>/.claude/hooks/scripts/` (preserving the `lib/` subdirectory structure). Word for word — do not paraphrase, reformat, or "improve" them while copying; if the scripts need a fix, fix them here in the plugin first, then re-run this skill.

4. **Merge the hook wiring into `<target-dir>/.claude/settings.json`.** Use `templates/vendored-hooks.json` as the source — it's identical to the plugin's own `hooks/hooks.json` except every `${CLAUDE_PLUGIN_ROOT}` is `$CLAUDE_PROJECT_DIR/.claude` (the vendored scripts' actual location). Read the target's existing `settings.json` (or start from `{}` if it doesn't exist yet) and merge:
   - For each event (`PreToolUse`, `PostToolUse`, `Stop`) in the template, if that event doesn't exist yet in the target, add it as-is.
   - If the event already exists, walk its matcher groups: if a group with the same `matcher` value already exists, append this template's `hooks` entries to that group's `hooks` array **only if an entry with the same `command` string isn't already present** (avoid double-adding on a re-run). If no group with that `matcher` exists yet, append the whole group.
   - Never touch any other key in the target's `settings.json` (`permissions`, `enabledPlugins`, `outputStyle`, etc.) — this is an additive merge, not a replace.

5. **Ensure `<target-dir>/.claude/harness.config.json` exists** (see `templates/harness.config.json.example`) — the vendored hooks read the same config keys the plugin's hooks do. If `harness-init` already ran here, this file exists; don't overwrite it, just confirm it's present. If it doesn't exist, create it following `harness-init` step 2's detection approach (read `<target-dir>/package.json` for the real gate commands).

6. **Add `.claude/harness-state/` to `<target-dir>/.gitignore`** if not already covered — same reason as `harness-init` step 3 (session-scoped log/marker files, noisy if untracked-but-ungitignored).

7. **Report a summary**: which scripts were copied (or already present and left untouched — this skill is safe to re-run, later steps should not duplicate on repeat), what was merged into `settings.json` (and what was left alone), whether the config file was created or already existed, and the double-coverage check result from step 2.

## What this skill does NOT do

- It does not touch anything in the plugin's own `hooks/scripts/` — it only reads from there.
- It does not vendor `hooks/examples/*.sh` (the layer-boundary/no-page-test/raw-package-install hooks) by default — those encode lista-natin-specific rules and were deliberately excluded from the plugin's own default `hooks.json` for the same reason. If the user explicitly asks for one of those too, copy it the same way (verbatim) and wire it in following its own header comment, but don't do this without being asked.
- It does not remove or replace an existing hook wiring for the same event/matcher that isn't one of this plugin's own scripts — only additive merging.
