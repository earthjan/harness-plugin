---
name: wireframe-html
description: Author a Tailwind-CDN wireframe.html or hifi.html mock that carries the real DESIGN.md spacing/typography/border-radius values, so it's 1:1-implementable in React Native. Use whenever creating or updating a wireframe/hi-fi HTML mock for a ticket, before it's handed off as a spec for React Native implementation.
---

# Wireframe/Hi-Fi HTML Authoring

Tailwind CDN's default utility scale (`gap-3`, `text-lg`, `rounded-lg`, …)
has no relationship to this project's real design tokens — using it
unmodified produces a mock that looks plausible but can't be traced back to
a DESIGN.md value. This skill closes that gap by locking the wireframe's
Tailwind config to the same source files the real theme is built from.
See `packages/wireframe-tokens/README.md` for the underlying mechanism.

## Steps

1. **Start the file pre-wired — never hand-type spacing, font-size, or
   border-radius numbers into a wireframe, and never hand-paste the config
   either.**

   New file:
   ```bash
   npm run wireframe:scaffold -- docs/tickets/<id>/wireframe.html
   ```

   Existing file, config gone stale (e.g. DESIGN.md changed):
   ```bash
   npm run wireframe:sync -- docs/tickets/<id>/wireframe.html
   ```

   Both use the same marked block
   (`<!-- WIREFRAME-TOKENS:START -->…END -->`) so re-running `sync` later
   always finds and replaces it in place — no manual copy-paste.

2. **Build the mock using only classes that resolve under that config.**
   The config *replaces* Tailwind's default spacing/fontSize/borderRadius
   scale (not `extend`), so a class using an off-scale key (`gap-3` meaning
   Tailwind's own 12px, `rounded-lg`) renders with no effect — visibly
   broken — instead of silently picking a value DESIGN.md never defined.
   Use the config's own key names: spacing `0.5/1/2/3/4/5/6` (DESIGN.md §2),
   font-size role names like `bodyLarge`/`titleMedium` (DESIGN.md §4), and
   radius names `pill/medium/chip/smallPill` (DESIGN.md §5).

3. **Annotate every element with the DESIGN.md role it uses**, via a
   `data-token` attribute — this is what the `ship-ui` Mock Element
   Inventory step reads instead of reverse-engineering intent from raw
   class names:

   ```html
   <div class="p-3 gap-2 rounded-pill" data-token="spacing:3 spacing:2 radius:pill">
     <p class="text-bodyLarge" data-token="type:bodyLarge">...</p>
   </div>
   ```

4. **Verify before handing off.** Run the verification script against the
   finished file — or just commit it, since the local pre-commit hook
   (`.githooks/pre-commit`) runs this automatically for every staged
   `docs/**/wireframe.html`/`docs/**/hifi.html` and blocks the commit if it
   fails:

   ```bash
   npm run wireframe:verify -- <path-to-wireframe.html>
   ```

   It exits non-zero and lists every offending class if any spacing/sizing/
   border-radius utility doesn't resolve under the locked config. Fix every
   finding before treating the wireframe as done.

   Note: the verifier does not check `text-` classes (Tailwind overloads
   that prefix for font-size, color, *and* alignment — see the package
   README for why). Font-size fidelity for `text-` relies on step 3's
   `data-token` annotations plus the Mock Element Inventory review, not this
   script.

## Non-negotiable

- Never hand-type a spacing/font-size/border-radius pixel value into a
  wireframe. If DESIGN.md doesn't have a token for what you need, that's a
  DESIGN.md gap to raise — not a reason to invent a number.
- Never `theme.extend` the locked scales — extending, instead of replacing,
  leaves Tailwind's own default scale reachable alongside the real one,
  which reintroduces the exact silent-drift failure this skill exists to
  close.
- Never hand-edit the `<!-- WIREFRAME-TOKENS:START -->…END -->` block — it's
  generated. Run `npm run wireframe:sync` instead, which is also how a
  wireframe stops drifting when DESIGN.md §2/§4/§5 changes later.
