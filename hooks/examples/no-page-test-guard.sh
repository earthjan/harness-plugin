#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit) — denies creating/editing a
# pages/**/*.test.ts(x) file. Pages are thin wiring only and are never
# tested directly — docs/project-structure/CONTEXT.md's "Testing Guidance
# Per Layer" table, lint-enforced by local/no-page-tests in
# eslint.config.js. This hook catches the mistake before it's even written;
# the lint rule catches everything else (files not touched via Claude,
# existing debt, CI).
set -euo pipefail

payload="$(cat)"
file_path="$(jq -r '.tool_input.file_path // empty' <<<"$payload")"
[ -z "$file_path" ] && exit 0

# Pre-existing violators tracked as debt in eslint.config.js's matching
# ignores list — grandfathered here too so an unrelated edit to one of them
# (e.g. a lint-warning fix) isn't blocked. Keep this list in sync with that
# one; it shrinks as each file is migrated, never grows.
grandfathered=(
  "modules/ledger/pages/Dashboard.test.tsx"
  "modules/ledger/pages/SessionTermsPreview.test.tsx"
  "modules/ledger/pages/SessionDetail.test.tsx"
  "modules/ledger/pages/CreateSession.test.tsx"
  "modules/ledger/pages/ContributionGrid.test.tsx"
  "modules/ledger/pages/PayoutOrder.test.tsx"
  "modules/ledger/pages/InviteSection.test.tsx"
  "modules/auth/pages/public/Login.test.tsx"
)
for allowed in "${grandfathered[@]}"; do
  [[ "$file_path" == *"$allowed" ]] && exit 0
done

if [[ "$file_path" =~ /pages/.*\.test\.tsx?$ ]]; then
  jq -n \
    --arg reason "pages/ is thin wiring only and is never tested directly (docs/project-structure/CONTEXT.md, Testing Guidance Per Layer; lint-enforced by local/no-page-tests). Move this assertion to the services/app-logic/ hook the page wires, or to the components/templates/ test — see .claude/skills/testable-app-logic/SKILL.md." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
fi

exit 0
