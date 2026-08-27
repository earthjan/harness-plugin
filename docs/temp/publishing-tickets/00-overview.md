# Publishing plan — spec-builder, workflow-builder, research-workflow

Scratch planning doc, not part of the ticket registry. Reviewed by an independent agent pass
(see "Review history" at the bottom) before being treated as ready to execute. Delete this whole
`publishing-tickets/` folder once the port is done and merged (the deletion step at the end of
"Commit," below, does this).

## What's moving

Three personal skills at `~/.claude/skills/` are getting ported into this plugin's `skills/` so
every project that installs `harness-plugin` gets them too:

- `spec-builder` — turns a rough idea/ticket into a build-ready `SPEC.md`, then hands off to
  `ship-ui`/`ship-non-ui`.
- `workflow-builder` — designs a maker/checker multi-agent workflow (stage decomposition, scored
  model routing, independent review) for any task that decomposes into checkable stages.
- `research-workflow` — a fixed 4-stage specialization of `workflow-builder`: research a feature,
  produce a cited `PROPOSAL.md`.

## Why these three, why now

`spec-builder` already assumes `ship-ui`/`ship-non-ui` and the `docs/tickets/` registry
conventions this plugin already ships — it was written against them. `research-workflow`
literally re-uses `workflow-builder`'s scoring rubric and review checklist at runtime, so it only
works if both ship together. Publishing all three in one pass avoids landing a skill with a
dangling dependency.

## Order

Tickets are numbered in the order to run them — `01-workflow-builder.md`,
`02-research-workflow.md`, `03-spec-builder.md`:

1. **`workflow-builder`** first — `research-workflow` depends on it.
2. **`research-workflow`** second — depends on `workflow-builder` only.
3. **`spec-builder`** third — depends on nothing new (its `ship-ui`/`ship-non-ui`/ticket-registry
   dependencies already exist in this plugin), but going last means if the first two surface a
   problem with the general porting approach, you find that on the smaller skills first.
4. **Shared doc edits** (this file, below) — do these once, after all three skill directories
   exist, not per-skill. Editing `CLAUDE.md`/`README.md` three times in a row for one shared
   bullet list just means resolving the same diff conflict three times.

Each per-skill ticket is self-contained and copy-paste runnable on its own.

## What's explicitly NOT moving, and why

Each source skill directory has more in it than the skill itself:

- **`NOTES.md`** (`spec-builder` only) — the author's own dev journal from benchmarking this
  skill against evals. Personal record, not skill content. Don't copy it.
- **`evals/`** (all three) — eval prompts/expected-outputs used to benchmark the skill during its
  own development. No skill in this plugin currently ships an `evals/` dir, so porting one in
  would be a new convention, not a continuation of an existing one. **Decision needed** (see
  below) — default recommendation is to leave these out for now.
- **The separate `*-workspace/` skill directories** (`spec-builder-workspace`,
  `workflow-builder-workspace`, `research-workflow-workspace`) — these are the raw benchmark run
  output (eval transcripts, grading JSON, timing data) the `evals/` dirs point back to. Not skill
  content at all; never copy these.

## Open decision: ship `evals/` or not?

Both options are legitimate; pick one before running the tickets below.

- **Leave it out (recommended default).** Matches how every other skill in this plugin already
  ships — no `evals/` anywhere in `skills/` today. Keeps the port mechanical: SKILL.md +
  references/assets only. Nothing stops adding eval coverage plugin-wide later, as its own
  decision, applied consistently across skills rather than starting with just these three.
  → Reflected in the per-skill ticket commands as-is.
- **Ship it anyway.** `evals/evals.json` in each skill is self-contained (prompt +
  expected_output + files, no path back into the `*-workspace/` run data — confirmed by reading
  all three) — it would copy cleanly without dragging the huge workspace dirs along. Keeps the
  regression-check capability these skills already have. If you want this, add
  `cp -r <src>/evals <dest>/` to each ticket's copy block.

## Portability check — what each skill assumes exists

Checked every `SKILL.md`, `references/`, and (for `workflow-builder`) `assets/templates/` file —
in full, not just skimmed — for anything pointing at a path or skill that has to exist in the
*consuming* project or in this plugin for the skill to actually work once installed. An
independent review pass (see bottom of this file) caught two real bugs a first read-through
missed; both are reflected in the table and in the per-skill tickets below.

| Skill | Depends on | Status |
|---|---|---|
| `spec-builder` | `ship-ui`, `ship-non-ui` (delivery hand-off) | ✅ already in `skills/` |
| `spec-builder` | `research-workflow` (heavy-path research) | ✅ published in this same batch |
| `spec-builder` | `docs/tickets/update-tickets-index.mjs`, `docs/tickets/<id>/CONTEXT.md` shape | ✅ matches `harness-init`'s own scaffolding exactly (`skills/harness-init/SKILL.md:29`) — no change needed |
| `workflow-builder` | `harness-engineering`, `ticket-effort` skills (named in description + section-header citations) | ⚠️ not in this plugin — content is fully inlined, only the framing needs a wording fix (see `01-workflow-builder.md`) |
| `workflow-builder` | its own `assets/templates/*.template` files hardcode `~/.claude/skills/workflow-builder/references/...` | ❌ **real bug, found on review** — these templates get copied into every project that uses this skill, so a bad path in them propagates outward every time the skill runs, not just once. Fixed in `01-workflow-builder.md` step 2b. |
| `research-workflow` | `workflow-builder` (re-uses its rubric/checklist at runtime) | ✅ published in this same batch, but the *reference itself* is hardcoded — see next row |
| `research-workflow` | hardcodes `~/.claude/skills/workflow-builder/references/scoring-rubric.md` in `SKILL.md` and `references/stage-prompts.md` | ❌ **real bug, found on review** — dead path once `workflow-builder` lives in `skills/workflow-builder/` instead. Fixed in `02-research-workflow.md` step 2. |
| `research-workflow` | `domain-griller` subagent (Stage 3) | ✅ already has a graceful fallback to `general-purpose` in `references/stage-prompts.md` — no change needed |

### The framing gap: `harness-engineering` / `ticket-effort` (workflow-builder only)

`workflow-builder`'s scoring rubric and review checklist are **fully inlined** in its own
`references/scoring-rubric.md` and `references/review-checklist.md` — verified by reading both in
full. The skill runs correctly with nothing else installed. The `harness-engineering §N` /
`ticket-effort` mentions in those files are provenance citations (where the rubric came from), not
runtime reads — nothing in the skill's steps says "go open the harness-engineering skill and read
it."

The one place this reads as a harder dependency than it is: the skill's own frontmatter
`description` says *"Builds directly on this user's harness-engineering and ticket-effort
skills — read those first if not already loaded."* That's true for the original author (who has
both installed globally) but misleading for a project that only installs `harness-plugin` — there
is nothing to "load." Fixed in `01-workflow-builder.md` step 2a (wording only, no functional
change).

## Shared doc edits (do once, after all three skill dirs exist)

### `CLAUDE.md` — `skills/` bullet

Find (in the `## Architecture` section):

```
- **`skills/`** — the installable behaviors: process skills (`tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`), the onboarding/generator skill (`harness-init`), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). No other agent has a matching skill; they're reached directly (see `agents/` below).
```

Replace with:

```
- **`skills/`** — the installable behaviors: process skills (`tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `spec-builder`, `workflow-builder`, `research-workflow`), the onboarding/generator skill (`harness-init`), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). `spec-builder` is the planning half of a two-skill pipeline with `ship-ui`/`ship-non-ui` (spec first, then delivery); `research-workflow` is a fixed specialization of `workflow-builder` and depends on it being installed. No other agent has a matching skill; they're reached directly (see `agents/` below).
```

### `README.md` — `skills/` bullet

Find (under `## What's in here`):

```
- **`skills/`** — `tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `harness-init` (the onboarding/generator skill — see below), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). No other agent has a matching skill; they're reached directly (see `agents/` below).
```

Replace with:

```
- **`skills/`** — `tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `spec-builder`, `workflow-builder`, `research-workflow`, `harness-init` (the onboarding/generator skill — see below), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). `spec-builder` is the planning half of a two-skill pipeline with `ship-ui`/`ship-non-ui`; `research-workflow` specializes `workflow-builder` and requires it installed alongside it. No other agent has a matching skill; they're reached directly (see `agents/` below).
```

Copy-paste command for both edits (run from repo root, after all three skills are copied — i.e.
after `01-workflow-builder.md`, `02-research-workflow.md`, `03-spec-builder.md` are done):

```bash
cd /Users/earthjan/repos/harness-plugin

python3 - <<'PY'
import pathlib

edits = [
    ("CLAUDE.md",
     "- **`skills/`** — the installable behaviors: process skills (`tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`), the onboarding/generator skill (`harness-init`), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). No other agent has a matching skill; they're reached directly (see `agents/` below).",
     "- **`skills/`** — the installable behaviors: process skills (`tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `spec-builder`, `workflow-builder`, `research-workflow`), the onboarding/generator skill (`harness-init`), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). `spec-builder` is the planning half of a two-skill pipeline with `ship-ui`/`ship-non-ui` (spec first, then delivery); `research-workflow` is a fixed specialization of `workflow-builder` and depends on it being installed. No other agent has a matching skill; they're reached directly (see `agents/` below)."),
    ("README.md",
     "- **`skills/`** — `tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `harness-init` (the onboarding/generator skill — see below), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). No other agent has a matching skill; they're reached directly (see `agents/` below).",
     "- **`skills/`** — `tdd`, `testable-app-logic`, `wireframe-html`, `regression-sweep`, `ship-non-ui`, `ship-ui`, `browser-verify`, `instructions-readme-drift-check`, `spec-builder`, `workflow-builder`, `research-workflow`, `harness-init` (the onboarding/generator skill — see below), and `tech-lead-review-with-fix` — the one skill that wraps an agent with real logic beyond dispatch (a review-then-fix loop). `spec-builder` is the planning half of a two-skill pipeline with `ship-ui`/`ship-non-ui`; `research-workflow` specializes `workflow-builder` and requires it installed alongside it. No other agent has a matching skill; they're reached directly (see `agents/` below)."),
]

for fname, old, new in edits:
    p = pathlib.Path(fname)
    text = p.read_text()
    assert old in text, f"anchor text not found in {fname} — file has drifted, edit by hand"
    p.write_text(text.replace(old, new, 1))
    print(f"updated {fname}")
PY
```

No `plugin.json` or `marketplace.json` change is needed — `plugin.json`'s `"skills": ["./skills"]`
auto-discovers every skill directory under `skills/`; nothing lists them by name.

## Verification (after all edits, all three skills)

```bash
cd /Users/earthjan/repos/harness-plugin

# 1. Confirm no leftover personal-machine paths in anything about to be committed —
#    the mechanical check the review pass says should always run, not just close-reading.
grep -rn "~/.claude/skills\|/Users/earthjan" skills/spec-builder skills/workflow-builder skills/research-workflow
# expect: no output. Any hit means a path from ~/.claude/skills/ leaked through uncorrected.

git status
git diff --stat
```

Then, in this repo (self-hosting — it's both the plugin and can install itself for a smoke test):

```
/plugin marketplace update earthjan-harness
```

and confirm `/harness-plugin:spec-builder`, `/harness-plugin:workflow-builder`,
`/harness-plugin:research-workflow` all show up as slash commands. Then run the
`instructions-readme-drift-check` skill against `CLAUDE.md`/`README.md` to confirm the two doc
edits above didn't leave anything else out of sync:

```
/instructions-readme-drift-check all docs
```

## Commit

One commit for the whole port (all three skills + both doc edits), not one per skill — they're
landing together because `research-workflow` doesn't work without `workflow-builder`, so a partial
commit would leave the repo in a broken intermediate state.

```bash
cd /Users/earthjan/repos/harness-plugin
git add skills/spec-builder skills/workflow-builder skills/research-workflow CLAUDE.md README.md
git commit -m "feat(skills): publish spec-builder, workflow-builder, research-workflow

Ports three personal skills into the plugin so every consuming project
gets them via /plugin marketplace update:
- spec-builder: rough idea/ticket -> build-ready SPEC.md, hands off to
  ship-ui/ship-non-ui
- workflow-builder: designs a maker/checker multi-agent workflow with
  scored model routing and a mandatory independent review pass
- research-workflow: fixed 4-stage specialization of workflow-builder
  for researching a feature into a cited PROPOSAL.md

workflow-builder's frontmatter description, and both skills' hardcoded
~/.claude/skills/workflow-builder/... references (in workflow-builder's
own output templates and in research-workflow's SKILL.md/stage-prompts),
are reworded to not point at the original author's personal machine —
a wording fix, not a functional change; the rubric/checklist content
was already fully inlined.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
git push
```

Then delete this planning doc — it's scratch, not part of the ticket registry, and its job is
done once the port lands. `docs/temp/publishing-tickets/` was never `git add`ed by the commit
above (only `skills/...`, `CLAUDE.md`, `README.md` were), so it's untracked the whole time —
deleting it is a plain filesystem cleanup, nothing to commit or push for it:

```bash
cd /Users/earthjan/repos/harness-plugin
rm -rf docs/temp/publishing-tickets
rmdir docs/temp docs 2>/dev/null || true   # only removes them if now empty; harmless no-op otherwise
```

## Review history

An independent agent (no prior context on this plan) reviewed all four planning files against the
real source/target files before this was treated as ready to execute. It verified every `cp`
source path, every exact-text find/replace block (byte-exact substring match against the real
`CLAUDE.md`/`README.md`), both Python heredoc scripts (syntax + actual diff produced), and the
portability claims — then caught two real bugs the first draft missed:

1. `research-workflow` hardcodes `~/.claude/skills/workflow-builder/references/scoring-rubric.md`
   in two places, contradicting the original ticket's "no content edits needed" claim.
2. `workflow-builder`'s own `assets/templates/*.template` files hardcode the same personal path in
   four places — worse than (1), because these templates get copied into every future project
   that uses the skill, so the bad path would have propagated outward every time it ran.

Both are fixed in the per-skill tickets below. It also caught one false verification claim
(`disable-model-invocation` was claimed as already-precedented in this plugin; it isn't —
`argument-hint` is, `disable-model-invocation` would be new) and one loose end (this file said to
delete `publishing-tickets/` but no step actually did it) — both fixed here.

A second independent review round then checked the fixes themselves — actually running both
Python heredoc scripts against real copies of the source files, confirming every `assert` passes
and the resulting diff matches what each ticket claims, and re-grepping all three source skill
directories (every file type, not just `.md`/`.template`) to confirm no further hardcoded personal
path was missed. All five first-round issues confirmed genuinely fixed. It caught one more bug in
the fix itself: the original deletion step tried to `git add -A docs/temp` and commit after
already `rm -rf`ing that same directory — since `docs/temp/publishing-tickets` was never tracked
in the first place, that `git add` would fail with "pathspec did not match any files" if pasted
verbatim. Fixed by dropping the doomed git commands — deleting an untracked scratch folder needs
no commit. Full findings from both rounds available in this session's transcript if needed later.
