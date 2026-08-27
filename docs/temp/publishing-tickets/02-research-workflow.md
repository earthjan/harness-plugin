# Ticket — publish `research-workflow`

Run this **second** — after `01-workflow-builder.md`, since this skill re-uses
`workflow-builder`'s rubric and review checklist at runtime.

## 1. Copy the skill

```bash
mkdir -p /Users/earthjan/repos/harness-plugin/skills/research-workflow
cp /Users/earthjan/.claude/skills/research-workflow/SKILL.md \
   /Users/earthjan/repos/harness-plugin/skills/research-workflow/SKILL.md
cp -r /Users/earthjan/.claude/skills/research-workflow/references \
      /Users/earthjan/repos/harness-plugin/skills/research-workflow/references
```

Deliberately **not** copied: `evals/` (same open decision as `workflow-builder` — add
`cp -r /Users/earthjan/.claude/skills/research-workflow/evals /Users/earthjan/repos/harness-plugin/skills/research-workflow/evals`
here if you opted in on `00-overview.md`).

## 2. Real fix — hardcoded personal path (found on independent review)

The first draft of this ticket claimed no content edits were needed. That was wrong: both
`SKILL.md` and `references/stage-prompts.md` hardcode the same personal path
`~/.claude/skills/workflow-builder/references/scoring-rubric.md` — dead once `workflow-builder`
lives at `skills/workflow-builder/` in this plugin instead of the original author's `~/.claude/`.

Two occurrences:

- `SKILL.md:46` — *"Score the four stages against `~/.claude/skills/workflow-builder/references/
  scoring-rubric.md`."*
- `references/stage-prompts.md:119` — *"score it against `~/.claude/skills/workflow-builder/
  references/scoring-rubric.md` anyway"*

Copy-paste command:

```bash
cd /Users/earthjan/repos/harness-plugin
python3 - <<'PY'
import pathlib

replacements = {
    "skills/research-workflow/SKILL.md": [
        ("2. **Score the four stages** against\n   `~/.claude/skills/workflow-builder/references/scoring-rubric.md`. In practice this shape",
         "2. **Score the four stages** against\n   workflow-builder's `references/scoring-rubric.md`. In practice this shape"),
    ],
    "skills/research-workflow/references/stage-prompts.md": [
        ("**Why Stage 4 is (almost) always `opus`:** score it against\n`~/.claude/skills/workflow-builder/references/scoring-rubric.md` anyway — don't skip the",
         "**Why Stage 4 is (almost) always `opus`:** score it against\nworkflow-builder's `references/scoring-rubric.md` anyway — don't skip the"),
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

If either `assert` fails, it's almost certainly a line-wrap difference — open the file, find the
line by its content (`grep -n "workflow-builder/references/scoring-rubric.md"`), and apply the
same substitution by hand instead of fighting the exact-match script.

## 3. Left as-is, deliberately

- Its dependency on `workflow-builder` itself is satisfied by `01-workflow-builder.md` being done
  first — nothing else to do there.
- Stage 3's `domain-griller` subagent already has a graceful fallback written in
  (`references/stage-prompts.md`): *"Check whether the target project has a `domain-griller`
  subagent/skill available before picking the fallback"* → falls back to `general-purpose`. A
  project without `domain-griller` installed still gets a working skill, just without that
  specific interrogation style.
- It reads project docs (`{{DOMAIN_GLOSSARY_DOC_PATH}}`, `{{DESIGN_SYSTEM_OR_CONVENTIONS_DOC}}`)
  as runtime placeholders filled in per-invocation, not fixed paths — portable by design already,
  same pattern `spec-builder` uses.

## 4. Verify

```bash
cd /Users/earthjan/repos/harness-plugin
ls skills/research-workflow/
# expect: SKILL.md  references/   (+ evals/ only if you opted in)

grep -rn "~/.claude/skills\|/Users/earthjan" skills/research-workflow
# expect: no output
```
