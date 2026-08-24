#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit|Read) — appends every file this
# session has touched to a per-session log. Used by tdd-gate.sh to check
# whether a sibling test file was touched before app-logic/core code.
set -euo pipefail

payload="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"
tool_name="$(jq -r '.tool_name // empty' <<<"$payload")"
file_path="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$payload")"

[ -z "$session_id" ] && exit 0
[ -z "$file_path" ] && exit 0

state_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-state"
mkdir -p "$state_dir"
log_file="$state_dir/${session_id}.touched.log"

# Dedup on append — cheap, log stays small for a normal session.
grep -qxF "$file_path" "$log_file" 2>/dev/null || echo "$file_path" >> "$log_file"

# Separate log of actual mutations (Write/Edit, not Read) — the Stop hook
# uses this to decide whether the tsc/lint/test gate even applies.
if [ "$tool_name" = "Write" ] || [ "$tool_name" = "Edit" ]; then
  edited_log="$state_dir/${session_id}.edited.log"
  grep -qxF "$file_path" "$edited_log" 2>/dev/null || echo "$file_path" >> "$edited_log"
fi

exit 0
