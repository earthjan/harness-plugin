#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit) — enforces "no test, no code" at the
# tool-call boundary. Blocks a Write/Edit to a non-test file under any of
# HARNESS_TDD_GATED_DIRS (default: services/app-logic/**, services/core/**
# — override per project via .claude/harness.config.json) unless a sibling
# *.test.ts(x) file has already been touched (Read/Write/Edit) earlier this
# session — i.e. Red before Green. See CLAUDE.md "Fundamental Authoring
# Practice".
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness-config.sh"

payload="$(cat)"
file_path="$(jq -r '.tool_input.file_path // empty' <<<"$payload")"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"

[ -z "$file_path" ] && exit 0

# Only gate files under one of the configured TDD-gated dirs.
gated=false
for d in $HARNESS_TDD_GATED_DIRS; do
  if [[ "$file_path" =~ /$d/.*\.tsx?$ ]]; then
    gated=true
    break
  fi
done
[ "$gated" = true ] || exit 0
# Never gate test files themselves.
if [[ "$file_path" =~ \.test\.tsx?$ ]]; then
  exit 0
fi

dir="$(dirname "$file_path")"
base="$(basename "$file_path")"
stem="${base%.*}"
candidate_ts="$dir/$stem.test.ts"
candidate_tsx="$dir/$stem.test.tsx"

touched_log="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-state/${session_id}.touched.log"

sibling_touched=false
if [ -f "$touched_log" ]; then
  if grep -qxF "$candidate_ts" "$touched_log" 2>/dev/null || grep -qxF "$candidate_tsx" "$touched_log" 2>/dev/null; then
    sibling_touched=true
  fi
fi

# A sibling test that already exists on disk and was written/read this
# session also satisfies Red-before-Green for a resumed session.
if [ "$sibling_touched" = false ]; then
  jq -n \
    --arg reason "TDD gate: no sibling test touched this session for '$file_path'. Per CLAUDE.md (\"No test, no code\"), write or open $candidate_ts (or .tsx) first — a failing test at the confirmed seam — before editing this file." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
fi

exit 0
