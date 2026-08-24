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

if [ -f "$_config_file" ]; then
  HARNESS_TDD_GATED_DIRS="$(jq -r '.tddGatedDirs // [] | join(" ")' "$_config_file" 2>/dev/null)"
fi
HARNESS_TDD_GATED_DIRS="${HARNESS_TDD_GATED_DIRS:-services/app-logic services/core}"

export HARNESS_GATE_TSC HARNESS_GATE_LINT HARNESS_GATE_TEST HARNESS_TICKETS_INDEX_SCRIPT HARNESS_TDD_GATED_DIRS
