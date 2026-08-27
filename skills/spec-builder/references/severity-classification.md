# Severity Classification — Reviewer Brief

This is the brief for the independent pass in Phase 3 of `spec-builder`. Give the subagent this
file plus the ticket's `SPEC.md` — nothing else. It should have no memory of drafting the spec;
that's the point of running this as a separate pass.

## Before checking anything

Read the current project's own `CLAUDE.md`, starting with its "Critical Documentation to Load
First" section (or equivalent), and open every doc it links, in the order it links them. That is
where *this* project defines its actual layer model, folder responsibilities, non-negotiable
boundaries, and data-integrity rules. Everything below is the shape of what to look for — apply it
against what this project's own docs actually say, never against another project's rules or
against any example folder name that happens to appear in this brief.

If `CLAUDE.md` is missing or has no doc-links section, check a sibling `CLAUDE.local.md` for an
`@`-import line (e.g. `@../CLAUDE.md`) — Claude Code's syntax for pulling in a parent directory's
CLAUDE.md, common in multi-repo setups. Follow one such hop and use that file's doc-links section
instead.

## The test

Not folder paths. A change can sit entirely inside a presentation/view file and still be critical
— for example, "compute this derived value inline in the component instead of consuming the
existing hook" never leaves a view file, but it's a boundary crossing if the project's own docs say
business logic doesn't belong there. Conversely, a change can touch a file in a "core logic"
directory and still be mechanical — a rename, a formatting fix, something the docs already settle
outright. Read for what the spec is actually asking someone to *decide*, not for which directory
its words point at.

Mark something **critical** when building it as written would require:

- A real business-rule or domain decision — something with more than one reasonable reading, where
  the project's own docs don't already settle it.
- Crossing a boundary between layers the project documents as separate (e.g., logic reaching into
  a layer that's supposed to stay presentation-only, or a data-access layer taking on business
  rules).
- A project-structure or coding-guideline-level call — where something new goes, what convention it
  should follow, whether it changes a documented invariant (e.g., an append-only log, an
  immutability rule, an ownership field).

Mark something **presentation-only** when it's confined to how something looks or is laid out, with
no new business rule and no boundary crossing — genuinely cheap to redo if it turns out wrong.

The line is the same one that governs whether an implementing agent should stop and ask instead of
guessing: if two people could reasonably land on different answers, or if getting it wrong changes
what other code assumes, it's critical — regardless of how small the surrounding change looks.
Mechanical, single-reading items aren't critical just because they touch a sensitive-sounding file.

## Keep the list short and real

This scale is deliberately binary — critical or presentation-only, no middle tier — because a
middle tier just gives borderline items somewhere to hide instead of forcing the real question:
does getting this wrong actually cost something. Two failure modes come from *not* asking that
question rigorously, and both were observed in practice on a genuinely complex ticket (a partial-
payments feature), where a first pass produced 12 "critical" items and roughly a third didn't hold
up under scrutiny:

- **A nicety gets marked critical.** If the honest downside of the "wrong" choice is that a reader
  has to do a bit of arithmetic, or a display is slightly less convenient — not that money, trust,
  or a data invariant is at risk — it's presentation-only, even if it technically involves a
  decision. "Someone could read it either way" is not the same test as "someone could reasonably
  build it either way, and the difference matters."
- **One real question gets split into three numbered items.** If several findings all trace back to
  the same underlying tension (e.g. three different angles on the same admin-workload tradeoff),
  that's one critical item with sub-options, not three separate ones. Splitting it multiplies how
  much of the user's attention it costs without adding any new decision.

Before finalizing the list, look back over every item marked critical and ask: if this one turned
out wrong, would it actually cost something to unwind, or would it just be mildly annoying? Cut or
merge anything that doesn't survive that question. A short, high-signal list that leads with what
truly needs a decision does more for the user than an exhaustive catalog of everything that was
technically ambiguous.

## Write-up format — every critical item, no exceptions

A severity tag on its own isn't a flag the user can act on; it's a flag they'd have to go translate
first. Write each critical item so it's understandable with zero outside context, in this order:

1. **What's being decided** — the real-world situation, in plain terms. Not "the `isLate` field in
   the submit handler" — "when someone tries to pay for a cycle that's already overdue, should the
   app let the payment go through late or block it."
2. **Why it's a judgment call** — what makes this ambiguous, specifically: two reasonable readings
   exist, or it's genuinely new ground the project's docs don't cover. If the docs already settle
   it, it isn't a judgment call — it shouldn't be marked critical in the first place.
3. **The options** — if there's a small known set, state them with their honest tradeoffs. Not a
   recommendation dressed as a foregone conclusion; the whole reason this is surfaced is for the
   user to decide, not to rubber-stamp a choice already made for them.

Any file or function name belongs at the end, as a footnote for whoever implements it later — never
as the explanation itself.

## Output

Return, per finding:
- `severity`: "critical" | "presentation-only"
- `decision` / `why-ambiguous` / `options` — the three-part write-up above, for every critical
  finding
- `citation`: the project doc/section this reasoning is grounded in, when there is one (e.g. "this
  project's data-integrity doc — '<the invariant as stated>'")

Only mark something critical with real confidence it clears the bar above — this list is what the
user reads first, so a false positive costs their attention on something that didn't need it, and a
false negative lets a real judgment call slip past unseen.
