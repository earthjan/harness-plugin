#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit) — keeps docs/tickets/INDEX.md in
# sync automatically instead of relying on the agent remembering to run
# the maintenance command after touching a ticket CONTEXT.md.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness-config.sh"

payload="$(cat)"
file_path="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$payload")"
[ -z "$file_path" ] && exit 0

if [[ "$file_path" =~ /docs/tickets/[^/]+/CONTEXT\.md$ ]]; then
  repo_root="${CLAUDE_PROJECT_DIR:-.}"
  if out="$(cd "$repo_root" && node "$HARNESS_TICKETS_INDEX_SCRIPT" 2>&1)"; then
    jq -n --arg msg "docs/tickets/INDEX.md regenerated after editing $(basename "$(dirname "$file_path")")/CONTEXT.md." \
      '{systemMessage: $msg}'
  else
    jq -n --arg msg "docs/tickets/INDEX.md regeneration failed after editing $file_path: $out" \
      '{systemMessage: $msg}'
  fi
fi

exit 0
