# Ticket — publish `workflow-builder`

Run this **first** (see `00-overview.md` for why) — `research-workflow` depends on it.

## 1. Copy the skill

```bash
mkdir -p /Users/earthjan/repos/harness-plugin/skills/workflow-builder
cp /Users/earthjan/.claude/skills/workflow-builder/SKILL.md \
   /Users/earthjan/repos/harness-plugin/skills/workflow-builder/SKILL.md
cp -r /Users/earthjan/.claude/skills/workflow-builder/references \
      /Users/earthjan/repos/harness-plugin/skills/workflow-builder/references
cp -r /Users/earthjan/.claude/skills/workflow-builder/assets \
      /Users/earthjan/repos/harness-plugin/skills/workflow-builder/assets
```

Deliberately **not** copied: `evals/` (see `00-overview.md`'s open decision — add
`cp -r /Users/earthjan/.claude/skills/workflow-builder/evals /Users/earthjan/repos/harness-plugin/skills/workflow-builder/evals`
here if you decided to ship it).

## 2a. Wording fix — frontmatter `description`

`SKILL.md`'s body, `references/scoring-rubric.md`, and `references/review-checklist.md` are fully
self-contained — verified by reading all of it in full; the rubric and checklist content is
already inlined, nothing requires reading an external skill at runtime. The one place this reads
as a harder dependency than it is: the frontmatter `description` promises a read that can't happen
once this ships standalone (`harness-engineering`/`ticket-effort` aren't published here).

Find, in `skills/workflow-builder/SKILL.md` line 3 (the `description:` line — this is its tail):

```
Builds directly on this user's harness-engineering and ticket-effort skills — read those first if not already loaded. For a fixed research-a-feature-and-produce-a-proposal shape specifically, use research-workflow instead, which specializes this skill.
```

Replace with:

```
The stage-decomposition test and model-scoring rubric are adapted from harness-engineering and ticket-effort methodology, fully inlined in this skill's own references/ — no separate skill install needed. For a fixed research-a-feature-and-produce-a-proposal shape specifically, use research-workflow instead, which specializes this skill.
```

## 2b. Real fix — hardcoded personal path in the output templates

Found on independent review, not in the first draft of this ticket: `assets/templates/*.template`
are the four files this skill copies into *other* projects every time someone uses it to design a
workflow. Three of them hardcode the original author's personal skills path
(`~/.claude/skills/workflow-builder/references/...`), which won't exist once this skill lives at
`skills/workflow-builder/` in the plugin instead. This is worse than a plain broken link — it
propagates into every `CONTEXT.md`/`MODEL-ROUTING.md`/`TASKS.md` this skill ever generates, not
just this one file.

Four occurrences, three files:

- `assets/templates/MODEL-ROUTING.md.template:4`
- `assets/templates/CONTEXT.md.template:28`
- `assets/templates/CONTEXT.md.template:70`
- `assets/templates/TASKS.md.template:23`

Copy-paste command — run both 2a and 2b together, after step 1:

```bash
cd /Users/earthjan/repos/harness-plugin
python3 - <<'PY'
import pathlib

# 2a — frontmatter description
skill = pathlib.Path("skills/workflow-builder/SKILL.md")
text = skill.read_text()
old = "Builds directly on this user's harness-engineering and ticket-effort skills — read those first if not already loaded. For a fixed research-a-feature-and-produce-a-proposal shape specifically, use research-workflow instead, which specializes this skill."
new = "The stage-decomposition test and model-scoring rubric are adapted from harness-engineering and ticket-effort methodology, fully inlined in this skill's own references/ — no separate skill install needed. For a fixed research-a-feature-and-produce-a-proposal shape specifically, use research-workflow instead, which specializes this skill."
assert old in text, "SKILL.md description has drifted from what this ticket expects, edit by hand"
skill.write_text(text.replace(old, new, 1))
print("updated skills/workflow-builder/SKILL.md (description)")

# 2b — hardcoded personal path in the emitted templates
replacements = {
    "skills/workflow-builder/assets/templates/MODEL-ROUTING.md.template": [
        ("`~/.claude/skills/workflow-builder/references/scoring-rubric.md` for the dimension",
         "workflow-builder's `references/scoring-rubric.md` for the dimension"),
    ],
    "skills/workflow-builder/assets/templates/CONTEXT.md.template": [
        ("`~/.claude/skills/workflow-builder/references/scoring-rubric.md`.",
         "workflow-builder's `references/scoring-rubric.md`."),
        ("`~/.claude/skills/workflow-builder/references/review-checklist.md`. Re-run it whenever this",
         "workflow-builder's `references/review-checklist.md`. Re-run it whenever this"),
    ],
    "skills/workflow-builder/assets/templates/TASKS.md.template": [
        ("| R1 | Independent review of this file set against `~/.claude/skills/workflow-builder/references/review-checklist.md` |",
         "| R1 | Independent review of this file set against workflow-builder's `references/review-checklist.md` |"),
    ],
}

for fname, pairs in replacements.items():
    p = pathlib.Path(fname)
    text = p.read_text()
    for old, new in pairs:
        assert old in text, f"anchor text not found in {fname}: {old!r} — file has drifted, edit by hand"
        text = text.replace(old, new, 1)
    p.write_text(text)
    print(f"updated {fname}")
PY
```

## 3. Left as-is, deliberately

- `SKILL.md`'s body line ("Break the task into stages using harness-engineering's graph-
  justification test: does the work independently decompose...") — the three questions right
  after the name ARE the test, spelled out in full. Naming the source is attribution, not an
  unresolved pointer. No edit needed.
- `references/review-checklist.md`'s section headers (`## 2. Instructions (harness-engineering
  §1)`, etc.) — same reasoning: each section's checklist items underneath are complete on their
  own; the `(harness-engineering §N)` is a citation, not an instruction to go read something else.
- `references/scoring-rubric.md`'s references to `/ticket-effort`'s rubric — it explicitly states
  it's reproducing that rubric minus one dimension, then reproduces it in full in the same file.
  Self-contained.
- `references/worked-example.md` — checked directly, no `~/.claude` or personal-path references at
  all.

## 4. Verify

```bash
cd /Users/earthjan/repos/harness-plugin
ls skills/workflow-builder/
# expect: SKILL.md  references/  assets/   (+ evals/ only if you opted in)

grep -rn "~/.claude/skills\|/Users/earthjan" skills/workflow-builder
# expect: no output — confirms both 2a and 2b actually applied
```
