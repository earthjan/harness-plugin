---
name: ship-ui
description: End-to-end UI delivery pipeline — plan, implement, review with UX and tech-lead agents iteratively, walkthrough. Use when the user provides a UI/UX spec, design document, feature description, or asks to "ship", "deliver", or "implement a feature" against a spec. Produces vetted, ready-to-commit code.
user-invocable: true
---

# /ship-ui — Deliver UI from Spec to Ready

Six-phase pipeline: **Plan → Implement → Blast-Radius Check → Review Loop → Goal-Satisfaction Review → Walkthrough**. Each phase gates on the previous. The main agent implements (as senior front-end engineer) and runs the Blast-Radius Check itself; subagents review (ux-reviewer for UX/design, the four tech-lead-review-* agents for architecture/code quality, goal-satisfaction-reviewer for spec compliance).

### Delivery Working Directory

Every artifact this pipeline writes (`PLAN.md`, `REVIEWS/`, `DELIVERY.md`, `WALKTHROUGH.md`) is placed in one **delivery working directory**. That directory is:

- the directory the user gave for this delivery (e.g. "put it in `docs/temp/foo`", a worktree path, a ticket's own directory), if they gave one — **use exactly that directory**, do not default to root once a directory is specified;
- otherwise, **the project root** — the default when the user gives no directory.

Resolve this once at the start of Phase 1 and reuse it for every artifact below — do not re-derive or default to root partway through the pipeline.

## Phase 1: Plan

1. Read the user's input. If they pointed at a spec file, read it in full. If they specified a directory for the delivery artifacts, that is the delivery working directory (see above) — note it now.
2. If the work maps to a ticket, start from the ticket registry — don't start zero-context: read `docs/tickets/INDEX.md` to locate the ticket, then read **only** that directory's `CONTEXT.md` **frontmatter** before opening any other file inside it. Do not read every file in a ticket directory — the CONTEXT.md is curated to point at what matters.
3. Create `PLAN.md` in the delivery working directory — preserves context across limited context windows.

**PLAN.md structure:**

- **Goal** — one-line summary
- **Acceptance Criteria** — numbered list of verifiable, behavior-level statements derived from the spec. Each criterion must be independently testable by reading code. One criterion per distinct behavior or requirement. If the spec has no explicit acceptance criteria, derive them from the goal and user stories. Subjective goals (e.g., "improve UX") must be translated into at least one observable change. If a goal is too vague to produce any verifiable criterion, flag it as an open question. **If a wireframe/mock file exists (see Mock Element Inventory below), every inventory entry becomes its own AC** — "matches the wireframe" is never itself an acceptable AC; the inventory item it stands for is.
- **Files to create** — list with brief descriptions
- **Files to modify** — list with brief descriptions
- **Implementation order** — numbered steps, each a concrete unit of work
- **Seams to test** — which public interfaces need coverage
- **Open questions** — anything blocking implementation start

**Mock Element Inventory** (required whenever a wireframe/mock HTML file exists for this delivery —
skip this subsection only when there is no such file):

In lista-natin's own history (`docs/tickets/103/0001_iteration` and `0002_iteration`), a delivery
shipped past a wireframe that was already correct — a dead row-tap handler, a missing status-chip
icon, a collapsed `marginBottom: 0` between cards, an overflowing member row — because the plan's
ACs were written at "view structure" grain instead of walking the mock element-by-element. A coarse
AC lets a coarse gap through
`goal-satisfaction-reviewer`, which only checks the diff against whatever ACs exist here.

Before writing any other PLAN.md section, walk the mock top to bottom and list every distinct element
as its own row: what it is (icon, chip, badge, spacing band, tap target), which DESIGN.md token it
maps to, and — if it looks interactive — what tapping it must do (navigate, open a sheet, change
state). Each row becomes one Acceptance Criterion, not a bucket item inside a broader one. Example
grain: "member row renders a leading status icon per §9," "row tap opens HulogDetailSheet," "cards
have a 16dp gap between them" — never "By Cycle view matches the wireframe."

**Completion criterion:** PLAN.md in the delivery working directory with all sections filled,
including a Mock Element Inventory when a wireframe/mock exists. Ambiguities → batch all questions to
user at once.

## Phase 2: Implement

Act as a **senior front-end engineer** for this project:

1. Follow the plan's implementation order sequentially.
2. TDD: write a failing test first, then only enough code to pass it.
3. Respect every UX/UI rationale and product decision in the spec.
4. No speculative features, no scope creep.

**Hard constraints (from project architecture):**

Read the current project's own `CLAUDE.md` — its "Non-Negotiable Boundaries" / "Architecture" section (naming varies by project) — and apply whatever hard constraints that project actually documents. Do not assume any specific stack, layer names, folder layout, or component-library convention; they are this project's own and vary from project to project.

If `CLAUDE.md` is missing or has no such section here, check a sibling `CLAUDE.local.md` for an `@`-import line (e.g. `@../CLAUDE.md`) — Claude Code's syntax for pulling in a parent directory's CLAUDE.md, common in multi-repo setups. Follow one such hop and use that file's section instead.

For example, a project might document constraints like "no Firebase imports outside `api/`", "no TanStack Query outside `query/`", "no business logic in pages/templates/UI components", "use `Lista`-prefixed shared components from `modules/shared/components` for standard controls", or "template-first: one template per screen, thin pages" — but treat these as illustrative only. Pull the real list from the current project's own docs before implementing.

**DESIGN.md compliance — decide per element while building, not at review time**

Read the current project's own `DESIGN.md` (or equivalent design-system doc) in full and use whatever section numbers and token names it actually defines — do not assume specific section numbers or token names belong to every project. At minimum, before building, confirm from the project's own doc:

- **Spacing:** every gap should map to a named spacing role/token the project's design doc defines, not a number that "looks plausible." Applies at every fidelity level, including greyscale wireframes — "low-fidelity" waives color/decoration, never measurements.
- **Type:** use the project's own type-scale tokens (and documented component dimensions — avatars, chips, touch targets, etc.) for every text element and sized component, at every fidelity level.
- **Reflow:** every list-row-shaped element (avatar + name + tag + amount, etc.) needs an explicit, decided-up-front reflow strategy per whatever "no scrolling"/reflow rule the project's design doc specifies — which content gets its own full-width line and never wraps/truncates first (typically the name), and which pieces share a line and degrade first (secondary info, then decorative elements). Verify it holds at more than the target device width — see `browser-verify`'s two-width mandate.

For example, lista-natin's own `DESIGN.md` documents this as §2 (spacing scale: micro 4dp, inline/icon 8dp,
card-internal/related-items 16dp, screen/card padding or generic section gap 24dp, section-to-section 32dp,
large section separation 40dp, major boundary 48dp), §4 (type scale), §9 (chip), §10 (touch targets), §11
(avatar), and §24 ("No Scrolling" reflow rule) — shown here as one illustrative example of what this kind
of constraint looks like, not as the section numbers to check in every project.

**Completion criterion:** All plan steps implemented. Run the project's configured gates — read
`gates.typecheck`, `gates.lint`, and `gates.test` from `.claude/harness.config.json` if that file exists in
the project, otherwise default to `npm run tsc`, `npm run lint`, and `npm test` respectively — all must
pass. **If PLAN.md has a Mock Element Inventory, run `browser-verify`'s interaction smoke check and
mock-parity check against it before Phase 3** — tap every element marked interactive and confirm an
observable effect, and walk each inventory row against the live screenshots with evidence (screenshot or
measurement), not a "looks right" summary.

## Phase 2.5: Blast-Radius Regression Smoke Check

Same "X.5" numbering placement as Phase 3.5 below, and Phase 2.5 does pick up two of that phase's
other traits: its own ledger (`REVIEWS/BLAST-RADIUS.md`, step 5 below) and a stated cap (5 screens,
step 3 below). What it doesn't pick up is Phase 3.5's maker/checker structure — an independent
subagent verifying the work. Phase 2.5 stays main-agent self-driven, the same shape Phase 2's own
`browser-verify` completion criterion already uses; it's cheap and bounded precisely because it
skips that extra review hop, not because it skips persistence or a cap.

This check is bounded to **this delivery's own reach** — did the diff just implemented break
something *outside* the screen it was building? It is not a substitute for `regression-sweep`
(see Related), which covers a whole sprint's worth of deliveries together, including interactions
between deliveries that individually looked fine.

1. **Identify blast radius — transitively, not single-hop.** Did this delivery modify or extend a
   hook/component/query/service with consumers outside the screen(s) it built or modified? A single
   grep pass is not sufficient — walk the import graph: grep for importers of the changed file(s),
   then grep for importers of *those* files, repeating until a `pages/`/`app/` route file is
   reached, the trail dead-ends, or a fixed hop budget is spent — size the budget to this
   project's own deepest documented layer chain (read its architecture doc; lista-natin's own
   chain is 4 hops, `api/` → `query/` → `services/app-logic/` → `pages/`, shown here as one
   illustration — a project with a deeper chain needs a higher budget, or the walk can stop short
   of a real consumer and understate blast radius). "Files
   this delivery created or modified" — the exclusion set for this walk — is the `git status
   --porcelain` output at this point in the pipeline (Phase 2.5 runs before Phase 3's `git add`, so
   there's no staged diff yet).
2. **No other consumers found** → record "No blast radius beyond this delivery's own screen(s)" in
   `REVIEWS/BLAST-RADIUS.md` (step 5), proceed to Phase 3. This is the common case and stays cheap.
3. **Other consumers found, capped at 5.** If more than 5 consuming screens are identified,
   smoke-check the 5 with the tightest coupling to the changed behavior (screens that call the
   changed function directly beat screens that only receive its output through several more hooks —
   not an arbitrary sample), and note in `REVIEWS/BLAST-RADIUS.md` that the remainder are deferred
   to the next `regression-sweep`, which already covers this seam's full consumer set. For each
   screen in the (capped) set, run `browser-verify`'s smoke check: load it, confirm it still renders
   without crashing, exercise the specific interaction path that touches the changed dependency.
   **Bounded** — this verifies the changed seam didn't break that screen, it is not a full feature
   audit of that screen.
4. **A real regression surfaces** → fix it now, same WIP=1 and test-first discipline as any other
   finding in this pipeline, then re-check the specific screen before continuing.
5. **Write results to `REVIEWS/BLAST-RADIUS.md` the moment the check runs — not deferred to
   Phase 4.** One row per consuming screen checked: screen, evidence (screenshot path or observed
   behavior), PASS/FAIL; plus the "no blast radius" note when step 2 applies, or the deferred-list
   note when step 3's cap is hit. Same "write immediately, merge later" pattern Phase 3 uses for
   `REVIEWS/iteration-NN/*.md` → `FINDINGS.md` — without it, these findings would live only in
   conversation context through Phase 3's up-to-5 review iterations and Phase 3.5's up-to-3
   goal-satisfaction iterations. Screenshots go under `screenshots/blast-radius/` in the delivery
   working directory.
6. **Stay current if a later fix touches new ground.** If a fix made during Phase 3 or Phase 3.5
   touches a hook/component/query/service with consumers not already covered by
   `REVIEWS/BLAST-RADIUS.md`, extend that record for the newly-touched seam before proceeding — an
   incremental check scoped to what actually changed, not a full Phase 2.5 re-run. The incremental
   check reuses step 1's transitive walk and step 3's 5-screen cap/selection rule, scoped only to
   the newly-touched seam. It cannot exceed step 3's cap in total: screens already checked earlier
   in this delivery don't re-count against the 5, so repeated re-triggers across Phase 3's/3.5's
   iterations stay bounded, not multiplied by the number of fixes. (See the exit-condition lines
   added to Phase 3 and Phase 3.5 below.)

**Completion criterion:** every consuming screen identified in step 1 (up to the step 3 cap) has
been smoke-checked with evidence in `REVIEWS/BLAST-RADIUS.md`, or the "no blast radius" note is
recorded — before staging for Phase 3.

## Phase 3: Review Loop

Stage all changes (`git add`) so the reviewers can inspect the diff. Review artifacts live in a `REVIEWS/` subdirectory placed in the delivery working directory (see above). All `REVIEWS/...` paths below are relative to that directory. Each iteration has two stages: **collect** (spawn reviewers, persist their raw output to disk) and **settle** (merge into the findings ledger, fix everything, update statuses). Every review cycle is documented in `REVIEWS/` before any fixing starts — no feedback lives only in context.

```
ITERATION = 0
LOOP:
  ITERATION += 1
  mkdir -p REVIEWS/iteration-$(printf %02d "$ITERATION")

  # Stage 1 — Collect: spawn reviewers, persist output, merge into ledger
  1. Spawn ux-reviewer → write raw output to REVIEWS/iteration-NN/ux-reviewer.md
  2. Spawn all four tech-lead-review-* agents → write raw output to
     REVIEWS/iteration-NN/<agent>.md (see Spawning Reviewers)
  3. Merge every finding into REVIEWS/FINDINGS.md (see Merging Findings)
     — all agents, no drops, stable IDs

  # Stage 2 — Settle: fix from the file, not from memory
  4. Fix every OPEN finding in REVIEWS/FINDINGS.md, updating each status to
     FIXED (with evidence) or WAIVED (with rationale)
  5. If any OPEN findings remain → goto LOOP
  6. If all FIXED → exit loop
```

### Spawning Reviewers

**Model routing (ticket-effort principle):** `ux-reviewer` and the four `tech-lead-review-*` agents all pin `model: haiku` in their own `.claude/agents/*.md` frontmatter (checklist audits against explicit docs) — that's the default, and it holds regardless of what model/effort the main session is running at. Before spawning, score *this diff* against ticket-effort's dimensions; pass `model: "sonnet"` as a per-invocation override to a specific reviewer only when the diff it's reviewing genuinely warrants it — cross-module scope, a new domain/financial/security invariant, an auth or schema change in that reviewer's territory, or a prior iteration where that same reviewer's findings look thin for the diff's actual complexity. State the reason when you escalate. Never escalate any of these seven past `sonnet` — no `opus`, ever, for these agents.

Spawn all in parallel (they audit independent concerns). **Persist before merge:** immediately after each reviewer returns, write its output verbatim to `REVIEWS/iteration-NN/<agent>.md`. If the output is unstructured, normalize it into the finding block format (below) while writing the file. Never merge from memory — if a reviewer's output is not on disk, it is not a finding.

On iteration ≥ 2, hand each reviewer the prior iteration's raw output file and `REVIEWS/FINDINGS.md` so it can (a) verify claimed fixes — a `FIXED` item that is not actually fixed must be re-reported as `OPEN` — and (b) avoid re-reporting genuinely resolved items.

```
Agent({subagent_type: "harness-plugin:ux-reviewer", description: "Audit UX copy, tone, and visual design on staged changes. Verify prior fixes in REVIEWS/FINDINGS.md; re-report any claimed-fixed item that is not actually fixed. Additionally check DESIGN.md compliance against whatever spacing/type/token sections this project's own DESIGN.md (or equivalent design-system doc) actually defines: (1) every spacing value maps to a named spacing role/token, not an off-scale number — flag any that don't; (2) type sizes and component dimensions use the project's own type-scale/token definitions at every fidelity level, not placeholder numbers; (3) every list-row-shaped element has an explicit reflow strategy per whatever reflow rule the project's design doc specifies, with evidence (screenshots) it was checked at more than one width per browser-verify's multi-width mandate, not just the target device. If PLAN.md has a Mock Element Inventory, walk that inventory row by row against the diff and the browser-verify evidence and report any row that is missing, unwired, or unverified — 'matches the wireframe' is not an acceptable claim, cite the specific row. (lista-natin's own history is the reason this inventory-walk step exists: an underspecified plan let a dead tap-handler, a missing chip icon, and a collapsed card gap all ship past a correct wireframe — watch for the equivalent gap here.)"})

Agent({subagent_type: "harness-plugin:tech-lead-review-architecture-enforcer", description: "Review staged changes (git diff --cached) for layer model, non-negotiable boundaries, and data-model integrity violations (e.g. Firestore rules, if this project uses Firestore). Verify prior fixes in REVIEWS/FINDINGS.md."})

Agent({subagent_type: "harness-plugin:tech-lead-review-code-quality", description: "Review staged changes (git diff --cached) for coding guideline violations — 20-line cap, CQS, cohesion, comments, dead code. Verify prior fixes in REVIEWS/FINDINGS.md."})

Agent({subagent_type: "harness-plugin:tech-lead-review-patterns", description: "Review staged changes (git diff --cached) for domain language, helpers/utils, OOP, copy objects, and component extraction violations. Verify prior fixes in REVIEWS/FINDINGS.md."})

Agent({subagent_type: "harness-plugin:tech-lead-review-tests", description: "Review staged changes (git diff --cached) for test placement, coverage, assertion quality, and TDD anti-patterns. Verify prior fixes in REVIEWS/FINDINGS.md."})
```

**Finding block format** (use for every finding in the per-agent file and in the ledger):

```
## <AGENT>-<NN> [<severity>] (iteration <N>)
- File: `path/to/file:line`
- Issue: <what is wrong>
- Suggested fix: <how to fix>
- Status: open
```

Severity mapping: UX `blocker` / `warning` / `suggestion` and tech `🔴 Must Change` / `🟡 Should Change` / `🔵 Nitpick` all normalize to **blocker** / **warning** / **nitpick** in the ledger.

### Merging Findings

Merge into `REVIEWS/FINDINGS.md` — the single cumulative fix queue for the whole review, updated in place across iterations. Rules:

- **Every finding from every agent gets a row and a stable ID** (agent prefix + sequence: `UX-01`, `ARC-02`, `QUAL-03`, `PAT-04`, `TST-05`). No finding is skipped — blockers, warnings, and nitpicks alike.
- **Agent-neutral:** preserve attribution, but treat all agents' findings equally. Do not filter, re-rank, or silently drop any reviewer's output. The fix pass must walk the whole ledger, not the agent you happened to remember.
- **Dedupe:** if two reviewers found the same issue, keep one entry and note both agent IDs.
- **Status lifecycle:** every row starts `open`. When fixed, mark `FIXED` with evidence (`file:line` or the verification that proves it). If you choose not to fix, mark `WAIVED` with an explicit rationale — waived items carry forward to DELIVERY.md and the readout. A claimed fix that a re-review reveals as not-fixed reverts to `open`.

On iteration ≥ 2, only append genuinely new findings; update statuses of existing rows (fixed → verified, claimed-fix-but-still-broken → open).

### Exit Conditions

- Every finding in `REVIEWS/FINDINGS.md` is `FIXED` and verified in re-review → proceed to Phase 4
- Iteration 5 reached with findings still `OPEN` or `WAIVED` → flag remaining items, proceed
- Same blocker persists across 2 iterations → flag for manual resolution, proceed
- Before proceeding: if any fix applied this iteration touched a hook/component/query/service with
  consumers not already covered by `REVIEWS/BLAST-RADIUS.md`, extend that record per Phase 2.5
  step 6 before moving on.

After loop exit, run the project's configured gates (see the Phase 2 completion criterion above for how to resolve them). Fix mechanical failures without re-review.

## Phase 3.5: Goal-Satisfaction Review

Verify that the delivered implementation satisfies the acceptance criteria in PLAN.md. This phase runs **regardless** of whether Phase 3 exited with flagged items — goal satisfaction is independent of code quality.

### Setup

Ensure PLAN.md contains an `## Acceptance Criteria` section. If missing, halt with a `FAIL` verdict and instruct the main agent to add it before proceeding.

### Review Loop

Every verdict is recorded in `REVIEWS/GOAL-SATISFACTION.md` — per iteration, per criterion: `PASS` / `PARTIAL` / `FAIL` with evidence. The ledger is updated in place and read by the readout and DELIVERY.md.

```
ITERATION = 0
LOOP:
  ITERATION += 1
  1. Spawn goal-satisfaction-reviewer → reads PLAN.md acceptance criteria and staged diff
  2. Record the verdict per criterion in REVIEWS/GOAL-SATISFACTION.md
  3. If PASS → exit loop, proceed to Phase 4
  4. If FAIL or PARTIAL → main agent addresses action items from the ledger, goto LOOP
  5. If ITERATION == 3 and not PASS → flag all unresolved criteria for manual resolution, proceed to Phase 4
```

### Spawning the Reviewer

`goal-satisfaction-reviewer` pins `model: haiku` in its own frontmatter (checklist against PLAN.md's acceptance criteria). Same escalation rule as the reviewers above — default haiku, escalate to `model: "sonnet"` per-invocation only when this ticket's acceptance criteria genuinely warrant it (high-stakes/ambiguous criteria), never past `sonnet`.

```
Agent({subagent_type: "harness-plugin:goal-satisfaction-reviewer", description: "Verifies that the delivered implementation satisfies the acceptance criteria in PLAN.md"})
```

### Acting on Findings

| Verdict  | Action |
|----------|--------|
| PASS     | Proceed to Phase 4 |
| PARTIAL  | Main agent addresses action items, re-review |
| FAIL     | Main agent addresses action items, re-review |

### Exit Conditions

- PASS verdict → proceed to Phase 4
- Iteration 3 reached with unresolved criteria → flag remaining items with their last status and evidence, proceed to Phase 4
- Before proceeding: if any action item addressed this iteration touched a hook/component/query/service with consumers not already covered by `REVIEWS/BLAST-RADIUS.md`, extend that record per Phase 2.5 step 6 before moving on.

## Phase 4: Delivery Record, Walkthrough & Readout

1. Write the post-implementation record to `DELIVERY.md` in the delivery working directory. This is the delivered state — separate from the plan — and a byproduct of the reviews: it captures what was actually implemented plus whatever the reviews surfaced.
2. Write the walkthrough to `WALKTHROUGH.md` in the delivery working directory — the navigable guide to the changes, built for the reader to move through them and know what to prioritize.
3. Present the final output as a readout — no confirmation gate — followed by a structured todo list of remaining items.
4. Register the progress and walkthrough in the ticket registry (see Registering Cross-Session Context below) so a new session working a related task starts with what's implemented, what's remaining, and the WHYs — not zero-context.

**DELIVERY.md structure:**

- **What was implemented** — files created and modified with brief descriptions, reflecting the actual delivered state after all reviews
- **Callouts** — notable points worth flagging: deviations from PLAN.md, decisions made during implementation, review findings and how they were resolved (waived findings carry their rationale here), plus a link to `REVIEWS/FINDINGS.md`; the blast-radius result copied from `REVIEWS/BLAST-RADIUS.md` (screens checked and evidence, or the no-blast-radius note), with a link to that file too
- **Remaining items** — anything left undone: unresolved findings, flagged criteria, open questions

**WALKTHROUGH.md structure:**

- **Escalations** — anything worth the reader's time that needs flagging or a decision: unresolved blockers, risky changes, out-of-scope modifications, follow-ups that need human judgment. If none, leave this section blank.
- **Walkthrough** — go file by file through every created and modified file. The point is the **WHYs**: for each file, why it was created/changed, why it is the way it is, and why it matters to the delivery. This is how the reader navigates the diff and builds a mental model of the change.

### Registering Cross-Session Context

The delivery-working-directory records document THIS delivery; the ticket registry is how a NEW session finds them. If the work maps to a ticket (see Phase 1), wire the artifacts into the ticket's directory — the entry point new sessions read first. The registry lives under `docs/tickets/`, resolved relative to the delivery working directory: `<delivery working directory>/docs/tickets/<id>/` — the same location rule everything else in this pipeline uses. All paths below are relative to that chosen location:

1. Copy `WALKTHROUGH.md` → `WALKTHROUGH.md` (matches the convention in tickets 93/94).
2. Copy `DELIVERY.md` → `PROGRESS.md` — the progress record: what's implemented, remaining items, and flags (matches the convention in ticket 96).
3. Update `CONTEXT.md`:
   - Add a **Key artifacts** section linking both files (`[PROGRESS.md](./PROGRESS.md)`, `[WALKTHROUGH.md](./WALKTHROUGH.md)`).
   - Update frontmatter: append "Ship walkthrough completed." to `description`, set `updated` to today's ISO date, and set `state: shipped` when only non-blocking remaining items are left.
4. Regenerate the registry from that location: `node docs/tickets/update-tickets-index.mjs`.

If the work does not map to a ticket, the root-level files are the record — no registry wiring applies.

### Readout Format

```
## Ship Complete

### What was built
> <one-line summary of the feature/change>

### Files Created
- path/to/file.tsx — <brief description>
- ...

### Files Modified
- path/to/file.tsx — <brief description>
- ...

### Blast-Radius Check
**Other consumers found:** <N> (<N checked> checked, <N deferred to next regression-sweep>) | **None**
<if any checked: screen-by-screen PASS/FAIL with evidence>

### Review Summary
**Phase 3 Iterations:** <N>
**Findings ledger:** `REVIEWS/FINDINGS.md` — <T> total findings (<T-fixed> fixed, <T-waived> waived, <T-open> open)

Pass 1: UX (<N blockers, N warnings, N suggestions>) | Tech (<N 🔴, N 🟡, N 🔵>)
  - Fixed: <key items fixed, with finding IDs>
Pass 2: ...
Pass N: Clean (0 open findings)

### Goal Satisfaction
**Ledger:** `REVIEWS/GOAL-SATISFACTION.md`
**Phase 3.5 Verdict:** PASS | PARTIAL | FAIL
**Iterations:** <N>
**Criteria Met:** <X>/<Y>
**Unresolved (if any):**
- Criterion #N: <status> — <summary of issue>

### Remaining Items
- [ ] <item> — <reason not resolved>

### Acceptance
- tsc: ✅ pass | ❌ <N errors>
- lint: ✅ pass | ❌ <N errors>
- test: ✅ pass | ❌ <N failures>

### Ready for commit
✅ All clear — ready for git add and commit.
— or —
⚠️ <N> items remain — review the remaining items above before committing.
```

### Persistence

Keep `PLAN.md`, `DELIVERY.md`, `WALKTHROUGH.md`, and the `REVIEWS/` directory (per-iteration raw outputs, `FINDINGS.md`, `GOAL-SATISFACTION.md`, `BLAST-RADIUS.md`, and `screenshots/blast-radius/`) in the delivery working directory after the walkthrough — do not delete them. Together they are the durable, documented record of the delivery: the plan, the per-iteration review feedback, the delivered reality, and the guide to navigating it. When the work maps to a ticket, the copies registered in the ticket directory (`PROGRESS.md`, `WALKTHROUGH.md`) are the cross-session entry points — keep them in sync if the delivery-working-directory files change.

## Key Behaviors

| Rule                     | Detail                                                               |
| ------------------------ | -------------------------------------------------------------------- |
| Plan first               | Create PLAN.md before writing any code                               |
| Document every review cycle | Persist each reviewer's raw output to REVIEWS/iteration-NN/ and merge all findings into REVIEWS/FINDINGS.md before fixing anything |
| Fix from the ledger      | Work the fix pass against REVIEWS/FINDINGS.md — every agent's findings get a stable ID; mark FIXED with evidence or WAIVED with rationale |
| Agent-neutral fixes      | No reviewer's findings are filtered, re-ranked, or dropped — a finding is a finding regardless of which agent produced it |
| Record delivery          | Write DELIVERY.md after the reviews — implemented state, callouts, remaining items |
| Walk the change          | Write WALKTHROUGH.md — escalations/flags up top, then WHY-driven per-file tour |
| Blast-radius smoke check | Phase 2.5 transitively walks consumers of any shared seam this delivery touched (capped at 5), before Phase 3 review — bounded to this diff's reach, not a full sweep; findings persist to `REVIEWS/BLAST-RADIUS.md` immediately |
| Main agent implements    | You are the senior FE — no subagent for implementation               |
| Subagents review         | ux-reviewer, the four tech-lead-review-* agents, and goal-satisfaction-reviewer spawned as subagents |
| Fix everything           | Clear blockers, warnings, AND nitpicks — nothing is skipped          |
| Walkthrough is a readout | Present final state and todo list — don't block on user confirmation |
| Delivery working directory | Resolve once up front: the directory the user specified for this delivery, else the project root. Every artifact below (PLAN.md, REVIEWS/, DELIVERY.md, WALKTHROUGH.md, ticket registry) goes there — never default to root once a directory is given |
| Persist artifacts        | Keep PLAN.md, DELIVERY.md, WALKTHROUGH.md, and REVIEWS/ in the delivery working directory; register PROGRESS.md + WALKTHROUGH.md in the ticket directory when the work maps to a ticket — do not delete them |

## Standalone Invocation

All reviewers are invocable directly outside this pipeline:

- `Agent({subagent_type: "harness-plugin:ux-reviewer"})` — audit any user-facing artifact (copy, design, tone)
- `Agent({subagent_type: "harness-plugin:tech-lead-review-architecture-enforcer"})` — review any branch/staged diff for layer model, boundaries, and data-model integrity
- `Agent({subagent_type: "harness-plugin:tech-lead-review-code-quality"})` — review any branch/staged diff for coding guideline violations
- `Agent({subagent_type: "harness-plugin:tech-lead-review-patterns"})` — review any branch/staged diff for domain language, patterns, and conventions
- `Agent({subagent_type: "harness-plugin:tech-lead-review-tests"})` — review any branch/staged diff for test placement, coverage, and assertion quality
- `Agent({subagent_type: "harness-plugin:goal-satisfaction-reviewer"})` — verify that delivered implementation satisfies acceptance criteria in PLAN.md

## Related

- `Skill({skill: "regression-sweep"})` — full cross-ticket regression verification at sprint end
  or before release; this pipeline's own gates (tsc/lint/test, the Phase 2 mock-parity smoke
  check, and Phase 2.5's blast-radius check) cover this delivery in isolation, `regression-sweep`
  covers everything shipped across a sprint, including cross-delivery interactions Phase 2.5 can't
  see
