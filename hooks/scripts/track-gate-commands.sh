#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash) — records, per session, whether each of
# the three required gates (npm run tsc / npm run lint / npm test) has been
# run and exited cleanly. Consumed by stop-gate-check.sh.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness-config.sh"

payload="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"
command="$(jq -r '.tool_input.command // empty' <<<"$payload")"
[ -z "$session_id" ] && exit 0
[ -z "$command" ] && exit 0

# Best-effort success signal: Bash tool_response commonly carries an
# isError/success flag; a missing field is treated as success (a failed
# command's stderr/exit code shows up in the transcript regardless — this
# hook only needs a coarse "was it attempted and not flagged as an error"
# signal, not a strict test-count check).
is_error="$(jq -r '(.tool_response.isError // .tool_response.is_error // false)' <<<"$payload")"
[ "$is_error" = "true" ] && exit 0

state_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/harness-state"
mark() {
  mkdir -p "$state_dir"
  touch "$state_dir/${session_id}.gate.${1}.ok"
}

# 1. Strip redirections (2>&1, >out.log, ...) so "npm test 2>&1" isn't
#    mistaken for "npm test" plus a stray "2" argument.
# 2. Split on command separators (&&, ||, ;, |) so a compound command like
#    "npm run tsc && npm run lint && npm test" — or "npm test 2>&1 | tail"
#    — is checked segment by segment.
# 3. Trim and exact-match each segment against the gate invocations.
stripped="$(sed -E 's/[0-9]*>{1,2}&?[0-9]*//g' <<<"$command")"
while IFS= read -r seg; do
  seg="$(sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' <<<"$seg")"
  case "$seg" in
    "$HARNESS_GATE_TSC") mark tsc ;;
    "$HARNESS_GATE_LINT") mark lint ;;
    "$HARNESS_GATE_TEST") mark test ;;
    # Anything else starting with the configured test command plus extra
    # args (a file path, -t, --testNamePattern) is a filtered/partial run —
    # it does not satisfy the full-suite test gate per CLAUDE.md, so it is
    # deliberately left unmarked.
  esac
done < <(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$stripped")

exit 0
