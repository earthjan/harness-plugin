#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit) — fast fail on the two mechanically
# checkable layer boundaries from CLAUDE.md before the write even lands:
#   - "No Firebase imports outside api/ folders."
#   - "No TanStack Query usage outside query/ folders."
# This is a fast, edit-time check on the content of THIS call only — the
# authoritative, whole-codebase version of the same rule is the
# no-restricted-imports blocks in eslint.config.js (npm run lint gate).
set -euo pipefail

payload="$(cat)"
file_path="$(jq -r '.tool_input.file_path // empty' <<<"$payload")"
[ -z "$file_path" ] && exit 0
[[ "$file_path" =~ \.tsx?$ ]] || exit 0

# Written/inserted text for this call — Write has `content`, Edit has
# `new_string`. Either way this is only the new text, not the whole file,
# which is enough to catch a freshly added import statement.
new_text="$(jq -r '.tool_input.content // .tool_input.new_string // empty' <<<"$payload")"
[ -z "$new_text" ] && exit 0

deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

if ! [[ "$file_path" =~ /api/ ]]; then
  if grep -qE "^[[:space:]]*(import .*from|.*require\()[[:space:]]*['\"](firebase(/|['\"])|@firebase/)" <<<"$new_text"; then
    deny "Layer boundary: '$file_path' imports firebase/@firebase outside an api/ folder. Firebase access belongs in api/ only — see CLAUDE.md Non-Negotiable Boundaries."
  fi
fi

if ! [[ "$file_path" =~ /query/ ]]; then
  if grep -qE "^[[:space:]]*(import .*from|.*require\()[[:space:]]*['\"]@tanstack/react-query['\"]" <<<"$new_text"; then
    deny "Layer boundary: '$file_path' imports @tanstack/react-query outside a query/ folder. TanStack Query usage belongs in query/ only — see CLAUDE.md Non-Negotiable Boundaries."
  fi
fi

exit 0
