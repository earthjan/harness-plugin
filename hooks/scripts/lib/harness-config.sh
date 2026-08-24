#!/usr/bin/env bash
# Shared config loader for harness-plugin hooks.
#
# Each consuming project may drop a .claude/harness.config.json at its
# root to override the defaults below (package manager differs — yarn vs
# npm — or the TDD-gated source dirs differ from lista-natin's
# services/app-logic|core layout). Missing file or missing key = default.
#
# Usage: source this file, then read $HARNESS_GATE_TSC / _LINT / _TEST /
# $HARNESS_TDD_GATED_DIRS (space-separated) / $HARNESS_TICKETS_INDEX_SCRIPT.

_config_file="${CLAUDE_PROJECT_DIR:-.}/.claude/harness.config.json"

_cfg() {
  # $1 = jq path, $2 = default
  if [ -f "$_config_file" ]; then
    jq -r "$1 // empty" "$_config_file" 2>/dev/null | grep -q . \
      && jq -r "$1" "$_config_file" 2>/dev/null && return
  fi
  printf '%s' "$2"
}

HARNESS_GATE_TSC="$(_cfg '.gates.typecheck' 'npm run tsc')"
HARNESS_GATE_LINT="$(_cfg '.gates.lint' 'npm run lint')"
HARNESS_GATE_TEST="$(_cfg '.gates.test' 'npm test')"
HARNESS_TICKETS_INDEX_SCRIPT="$(_cfg '.ticketsIndexScript' 'docs/tickets/update-tickets-index.mjs')"

# A project can explicitly opt out of TDD gating entirely with
# "tddGatedDirs": [] (e.g. a codebase that doesn't use the
# services/app-logic|core layout the default assumes). That must be
# distinguished from the key being absent, which still means "use the
# default" — so we only populate HARNESS_TDD_GATED_DIRS (even as an
# empty string) when the key is actually present in the config, and
# use bash's unset-only fallback ("-", not ":-") below so an
# intentionally empty value survives instead of being treated as
# "not set."
if [ -f "$_config_file" ] && jq -e '.tddGatedDirs != null' "$_config_file" >/dev/null 2>&1; then
  HARNESS_TDD_GATED_DIRS="$(jq -r '.tddGatedDirs | join(" ")' "$_config_file" 2>/dev/null)"
fi
HARNESS_TDD_GATED_DIRS="${HARNESS_TDD_GATED_DIRS-services/app-logic services/core}"

export HARNESS_GATE_TSC HARNESS_GATE_LINT HARNESS_GATE_TEST HARNESS_TICKETS_INDEX_SCRIPT HARNESS_TDD_GATED_DIRS
