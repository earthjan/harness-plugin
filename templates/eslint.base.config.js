// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require("eslint/config");
const expoConfig = require("eslint-config-expo/flat");
const localRules = require("@lista-natin/eslint-rules");
const globals = require("globals");
module.exports = defineConfig([
  expoConfig,
  {
    // packages/wireframe-tokens ships plain CommonJS .js (no build step —
    // its CLI entry points must run under plain `node`, unlike
    // packages/domain's TS-with-a-build-step convention). TS test files
    // elsewhere get `describe`/`it`/`expect` for free from tsconfig's
    // `types: ["jest"]`; plain .js has no equivalent, hence declaring the
    // globals explicitly here instead.
    files: ["packages/wireframe-tokens/**/*.js"],
    languageOptions: {
      globals: { ...globals.node, ...globals.jest },
    },
  },
  {
    // Defense in depth: docs/**/*.html (wireframe/hi-fi mocks) is already
    // outside the `npm run lint` glob, which never names `docs`. This makes
    // that exclusion explicit rather than incidental — see
    // packages/wireframe-tokens/README.md for why these files must never
    // enter the app build/lint/tsc surface.
    ignores: ["docs/**/*.html"],
  },
  {
    settings: {
      "import/resolver": {
        typescript: {
          alwaysTryTypes: true,
          project: "./tsconfig.json",
        },
      },
    },
  },
  {
    rules: {
      "react-hooks/rules-of-hooks": "error",
    },
  },
  {
    files: [
      "modules/**/services/**/*.{ts,tsx}",
      "modules/**/query/**/*.{ts,tsx}",
      "modules/**/api/**/*.{ts,tsx}",
      "modules/**/types/**/*.{ts,tsx}",
    ],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["**/components/**", "**/pages/**"],
              message:
                "Model layers (services/query/api/types) must never import from components/ or pages/, even type-only. Types flow model -> view. See docs/system-architecture/CONTEXT.md (Type Ownership & One-Way Type Flow).",
            },
          ],
        },
      ],
    },
  },
  {
    // "No Firebase imports outside api/ folders." (CLAUDE.md Non-Negotiable
    // Boundaries). Anchored regex, not a glob `group` — a `group` glob is
    // matched via gitignore-style "ignore" semantics, which does not anchor
    // to the start of the specifier and false-positives on every relative
    // import of an api/ module from elsewhere (e.g. "../api/firebase/sessions"
    // matches a "firebase/*" glob even though it's the sanctioned api/ folder
    // being imported FROM, not a firebase import from outside it). The regex
    // requires the specifier to literally start with the package name, which
    // a relative "../" or "./" import never does.
    //
    // Warn, not error: modules/auth/query/useAuthSession.ts has one
    // pre-existing value import of onAuthStateChanged that predates this
    // rule — fixing it is tracked separately, not blocking this lint gate.
    files: ["modules/**/*.{ts,tsx}", "functions/src/**/*.{ts,tsx}"],
    ignores: ["**/api/**"],
    rules: {
      "no-restricted-imports": [
        "warn",
        {
          patterns: [
            {
              regex: "^(firebase(-admin)?(/.*)?|@firebase/.*)$",
              message:
                "Firebase imports are only allowed in api/ folders. See CLAUDE.md Non-Negotiable Boundaries.",
            },
          ],
        },
      ],
    },
  },
  {
    // "No TanStack Query usage outside query/ folders." (CLAUDE.md
    // Non-Negotiable Boundaries). Regex for the same reason as the Firebase
    // block above. No pre-existing violators, so this is a hard error.
    files: ["modules/**/*.{ts,tsx}"],
    ignores: ["**/query/**"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              regex: "^@tanstack/react-query(/.*)?$",
              message:
                "TanStack Query usage is only allowed in query/ folders. See CLAUDE.md Non-Negotiable Boundaries.",
            },
          ],
        },
      ],
    },
  },
  {
    files: ["modules/**/components/**/*.{ts,tsx}", "modules/**/pages/**/*.{ts,tsx}"],
    plugins: { local: localRules },
    rules: {
      // DESIGN.md §2 spacing-scale check. See docs/temp/ui-harness-improvement.
      "local/spacing-scale": "error",
      // DESIGN.md §5a border-width-scale check.
      "local/border-width-scale": "error",
    },
  },
  {
    // "pages/ is thin wiring only" and is never tested directly (docs/project-structure/CONTEXT.md,
    // Testing Guidance Per Layer). Hard error for new files; the pre-existing violators below are
    // tracked debt (migrate their assertions to the services/app-logic/ hook or
    // components/templates/ test — see .claude/skills/testable-app-logic/SKILL.md) rather than
    // grandfathered forever.
    files: ["modules/**/pages/**/*.test.{ts,tsx}"],
    ignores: [
      "modules/ledger/pages/SessionTermsPreview.test.tsx",
      "modules/ledger/pages/SessionDetail.test.tsx",
      "modules/ledger/pages/CreateSession.test.tsx",
      "modules/ledger/pages/ContributionGrid.test.tsx",
      "modules/ledger/pages/PayoutOrder.test.tsx",
      "modules/ledger/pages/InviteSection.test.tsx",
      "modules/auth/pages/public/Login.test.tsx",
    ],
    plugins: { local: localRules },
    rules: {
      "local/no-page-tests": "error",
    },
  },
  {
    files: ["**/*.test.{ts,tsx}"],
    plugins: { local: localRules },
    rules: {
      // Test descriptions describe behavior, not provenance — no ticket/PR/
      // issue/file-name references. See CLAUDE.md (Naming Conventions) and
      // .claude/skills/tdd/tests.md.
      "local/test-description-self-contained": "error",
    },
  },
  {
    files: ["modules/**/*.{ts,tsx}", "functions/src/**/*.{ts,tsx}"],
    plugins: { local: localRules },
    rules: {
      // Comments are a last resort per docs/coding-guidelines/CONTEXT.md §11:
      // no ticket/PR/issue references or historical narrative in source, and
      // any justified comment must be tagged (// ! or // *) and short.
      //
      // Warn, not error: this rule surfaces a large amount of pre-existing
      // narrative-comment debt across the codebase. Fixing it in bulk is
      // tracked separately (see docs/coding-guidelines/CONTEXT.md §11) — new
      // code should not add more, but this gate does not block unrelated PRs
      // on cleaning up old files it happens to touch.
      "local/no-narrative-comments": "warn",
    },
  },
  {
    // eslint-plugin-import's import/namespace cannot resolve the "/v1"
    // subpath export of firebase-functions (a package.json "exports" map
    // interop gap), so it false-positives "'region' not found in imported
    // namespace 'functions'" etc. for `import * as functions from
    // "firebase-functions/v1"` even though the code type-checks cleanly
    // (npm run tsc) and matches the official v1 API. Disabled for
    // functions/src only, where that import pattern lives.
    files: ["functions/src/**/*.{ts,tsx}"],
    rules: {
      "import/namespace": "off",
    },
  },
  {
    ignores: ["dist/*"],
  },
]);
