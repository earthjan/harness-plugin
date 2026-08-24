#!/usr/bin/env bash
# Stop hook — verifies the CLAUDE.md three-gate requirement (npm run tsc,
# npm run lint, npm test, all passing) ran THIS session before Claude stops,
# but only when this session actually changed a source file. Blocks once;
# if the harness re-invokes this hook because it already blocked
# (stop_hook_active), it lets the stop through rather than looping forever.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness-config.sh"

payload="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"
stop_hook_active="$(jq -r '.stop_hook_active // false' <<<"$payload")"

[ -z "$session_id" ] && exit 0
[ "$stop_hook_active" = "true" ] && exit 0

state_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-state"
edited_log="$state_dir/${session_id}.edited.log"

# Nothing was written/edited this session — the gate doesn't apply
# (read-only / conversational turns shouldn't be blocked on tsc/lint/test).
[ -f "$edited_log" ] || exit 0
grep -qE '\.(ts|tsx)$' "$edited_log" 2>/dev/null || exit 0

missing=()
[ -f "$state_dir/${session_id}.gate.tsc.ok" ] || missing+=("$HARNESS_GATE_TSC")
[ -f "$state_dir/${session_id}.gate.lint.ok" ] || missing+=("$HARNESS_GATE_LINT")
[ -f "$state_dir/${session_id}.gate.test.ok" ] || missing+=("$HARNESS_GATE_TEST (full suite, unfiltered)")

if [ "${#missing[@]}" -eq 0 ]; then
  exit 0
fi

joined="$(printf '%s, ' "${missing[@]}")"
joined="${joined%, }"
jq -n --arg reason "Three-gate check: this session edited .ts/.tsx files but hasn't run: $joined. Per CLAUDE.md, all three must pass with zero errors before the change is done — run them now." \
  '{decision: "block", reason: $reason}'
exit 0
