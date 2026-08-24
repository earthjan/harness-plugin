#!/usr/bin/env bash
# EXAMPLE HOOK — not wired into the plugin's default hooks.json. This is
# lista-natin's own rule (an Expo/React Native project needs deps added via
# `npx expo install`, not raw npm/yarn/pnpm) and would incorrectly block
# every ordinary `yarn add`/`npm install <pkg>` in a project that isn't
# Expo-based. Copy this into a project's own local hooks (and adjust the
# deny message) only if that project genuinely has an equivalent
# must-use-this-installer rule. See hooks/examples/ in the plugin README.
#
# PreToolUse hook (matcher: Bash) — blocks adding a package with a raw
# npm/yarn/pnpm install command. Expo/React Native packages must be added
# via `npx expo install <package>` so Expo can pin a compatible version.
# Bare `npm install` / `npm ci` (no package args — reinstalling from
# package.json/lockfile) is left alone.
set -euo pipefail

payload="$(cat)"
command="$(jq -r '.tool_input.command // empty' <<<"$payload")"
[ -z "$command" ] && exit 0

if grep -qE '(^|[;&|]|[[:space:]])(yarn[[:space:]]+add|pnpm[[:space:]]+add|npm[[:space:]]+(install|i)[[:space:]]+[^-][^[:space:]]*)' <<<"$command"; then
  jq -n \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "Use `npx expo install <package-name>` to add dependencies in this repo, not npm install / yarn add / pnpm add — see CLAUDE.md Commands. Bare `npm install`/`npm ci` (no package args) is fine."}}'
  exit 0
fi

exit 0
