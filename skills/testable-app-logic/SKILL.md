---
name: testable-app-logic
description: Testable application-logic hooks. Use when writing or refactoring hooks, orchestration, form or state logic, or any feature with business rules — the thin wire-up hook + testable unit pattern (core class, pure function, or DI sub-hook).
---

# Testable Application Logic Guide

How to write `services/app-logic/` hooks so the high-value behavior is testable — with or without a class.

> **Reference skill.** The canonical rules live in `docs/*/CONTEXT.md`, `CLAUDE.md`, and the `tdd` skill. In case of conflict, canonical docs take precedence.

## Sources

This guide codifies patterns observed in the codebase. The authoritative rules come from:

- `CLAUDE.md` — layer model, non-negotiable boundaries
- `docs/project-structure/CONTEXT.md` — placement decision table, folder responsibilities
- `docs/coding-guidelines/CONTEXT.md` — CQS, cohesion, comment rules, TDD workflow
- `docs/system-architecture/CONTEXT.md` — data flow, Presenter/Model boundaries
- `.claude/skills/tdd/SKILL.md` — red-green-refactor loop, test naming, mock boundaries

## The Core Idea

A page imports **one thin hook**. That hook is a **wire-up shell**: it assembles real dependencies (Firebase calls, TanStack Query hooks, navigation, etc.) and hands them to a **testable unit** that contains all the business logic, validation, and decision-making. The wire-up shell is intentionally untested. The testable unit is where TDD happens.

```
Page (presenter)         Thin wire-up hook            Testable unit
───────────────         ──────────────────            ──────────────
uses useMyFeature()  →  assembles real deps       →   has all the behavior
                        creates/invokes unit           ← tested directly
                        returns thin callbacks
```

The testable unit can be a **class**, a **pure function**, or **another hook** — whatever fits the logic it holds.

---

## Pattern A: Thin Hook → Core Class (DI via Interface)

Use when the operation orchestrates **multiple side-effectful steps** (read data, validate, write, notify, log) and the logic is naturally sequential.

### Structure

```
services/
├── core/
│   ├── MyFeature.ts              ← Class with Deps interface, constructor injection
│   └── MyFeature.test.ts         ← Tests with plain-object test doubles
├── app-logic/
│   └── useMyFeature.ts           ← Thin hook (intentionally untested)
```

### Core class (`services/core/MyFeature.ts`)

```typescript
// 1. Define a Deps interface — one method per side-effect
export interface MyFeatureDeps {
  getSession(sessionId: string): Promise<Session | null>;
  createBatch(): BatchWriter;
  // ...
}

// 2. Class takes deps via constructor
export class MyFeature {
  constructor(private readonly deps: MyFeatureDeps) {}

  async execute(input: MyFeatureInput): Promise<MyFeatureResult> {
    // all business logic lives here
    const session = await this.deps.getSession(input.sessionId);
    this.#validate(session, input);
    const batch = this.deps.createBatch();
    // ...
    await batch.commit();
    return { ... };
  }

  #validate(session: Session, input: MyFeatureInput): void { ... }
}
```

**Rules for the core class:**
- Zero Firebase imports. Zero React imports. Zero TanStack Query imports.
- All side-effects go through `this.deps`.
- Time-dependent logic receives `now: Date` as a parameter (never calls `new Date()` internally).
- Sub-validators are separate classes or pure functions, tested independently.

### Thin hook (`services/app-logic/useMyFeature.ts`)

```typescript
/**
 * Thin React hook that wires the MyFeature class to real deps.
 * The class is memoized via useMemo and is the sole source of business logic.
 * Zero Firebase imports — all side-effects come from api/.
 * This hook is intentionally untested — it's pure wire-up.
 */

export function useMyFeature() {
  const instance = useMemo(() => {
    const deps: MyFeatureDeps = {
      getSession: (sessionId) => getSessionById(sessionId),
      createBatch: () => createFirestoreBatchWriter(),
    };
    return new MyFeature(deps);
  }, []);

  const execute = useCallback(
    (input: MyFeatureInput) => instance.execute(input),
    [instance],
  );

  return { execute };
}
```

### Tests (`services/core/MyFeature.test.ts`)

- Use **plain-object test doubles** (objects with tracking arrays), not `jest.fn()`.
- Use factory functions (`makeSession()`, `makeParticipant()`) to build test data.
- Test sub-validators and pure helper functions directly.
- Follow `describe(ClassName.name, ...)` and `it("should ...", ...)` naming.

```typescript
function makeTestDeps(overrides?: Partial<MyFeatureDeps>): MyFeatureDeps & { _batch: TestBatch } {
  const batch = makeTestBatch();
  return { getSession: async () => makeSession(), createBatch: () => batch, _batch: batch, ...overrides };
}

describe(MyFeature.name, () => {
  it("should ...", async () => {
    const deps = makeTestDeps();
    const feature = new MyFeature(deps);
    await feature.execute({ ... });
    expect(deps._batch.writes).toEqual([...]);
  });
});
```

### When a class fits

- Sequential multi-step orchestration (fetch → validate → write → notify)
- Multiple side-effect dependencies that benefit from an interface contract
- The logic maps cleanly to private methods on a class

---

## Pattern B: Thin Hook → Pure Function

Use when the hook's job is to **transform data** with no side effects. The pure function takes inputs, returns outputs. No async, no API calls, no mutation.

### Structure

**Option 1 — pure function in the same file as the hook:**

```
services/
├── app-logic/
│   ├── useDashboardStats.ts       ← Hook + exported pure function in same file
│   └── useDashboardStats.test.ts  ← Tests the pure function, NOT the hook
```

**Option 2 — pure function in `core/`, test co-located with the hook:**

```
services/
├── core/
│   └── mergeDashboardSessions.ts      ← Pure function
├── app-logic/
│   ├── useDashboardRawSessions.ts     ← Thin hook, untested
│   └── useDashboardRawSessions.test.ts ← Tests the core function (imported)
```

The test can also live directly next to the core function (`core/mergeDashboardSessions.test.ts`) — both placements are valid. The codebase uses the co-located-with-hook approach for this example.

### Pure function + thin hook (same file)

```typescript
// useDashboardStats.ts

export function computeDashboardStats(
  enrichedSessions: EnrichedDashboardSession[],
  now: Date = new Date(),
): DashboardStats {
  // all business logic — classification, aggregation, comparison
  // zero imports from api/, query/, or React
}

export function useDashboardStats(
  enrichedSessions: EnrichedDashboardSession[],
): DashboardStats {
  return useMemo(() => computeDashboardStats(enrichedSessions), [enrichedSessions]);
}
```

### Pure function in core, hook in app-logic

```typescript
// core/mergeDashboardSessions.ts
export function mergeAndSortDashboardSessions(
  adminSessions: SessionWithEnrichment[],
  participantSessions: SessionWithEnrichment[],
): SessionWithEnrichment[] { ... }

// app-logic/useDashboardRawSessions.ts
export function useDashboardRawSessions(userId: string) {
  const { data: adminData } = useAdminSessionsQuery(userId);
  const { data: participantData } = useParticipantSessionsQuery(userId);

  const sessions = useMemo(() => {
    if (!adminData || !participantData) return [];
    return mergeAndSortDashboardSessions(adminData, participantData);
  }, [adminData, participantData]);

  return sessions;
}
```

### Tests

- Import the pure function directly. No React rendering, no mocks.
- Pass plain objects and an explicit `now` date.
- One logical assertion per test.

```typescript
import { computeDashboardStats } from "./useDashboardStats";

describe(computeDashboardStats.name, () => {
  it("should return zero stats when there are no sessions", () => {
    expect(computeDashboardStats([], new Date("2026-03-15"))).toEqual({
      activeCount: 0,
      // ...
    });
  });
});
```

### When a pure function fits

- The hook's primary job is a `useMemo` over input data
- No async operations or side effects involved
- The transform is complex enough to deserve its own tests

---

## Pattern C: Testable Sub-Hook (DI via Props)

Use when the logic **needs React state, effects, or lifecycle** and splitting into a class would fight React's model. The sub-hook receives its dependencies as props/parameters — not by importing them directly. The sub-hook IS the testable unit. A thin outer hook wires real deps into it.

### Structure

```
services/
├── app-logic/
│   ├── useMyFeatureState.ts       ← Testable sub-hook (DI via params)
│   ├── useMyFeatureState.test.tsx  ← Tests via custom renderHook harness
│   └── useMyFeature.ts            ← Thin wire-up hook (untested)
```

### Testable sub-hook (`useMyFeatureState.ts`)

```typescript
// useMyFeatureState.ts

type UseMyFeatureStateDeps = {
  saveDraft(data: DraftData): Promise<string>;
  validateForm(data: FormInput): Promise<boolean>;
  onNavigateAway(): void;
};

export function useMyFeatureState(deps: UseMyFeatureStateDeps) {
  const [step, setStep] = useState<"form" | "review" | "confirm">("form");
  const [isSaving, setIsSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const goToReview = useCallback(async (data: FormInput) => {
    const valid = await deps.validateForm(data);
    if (!valid) return;
    setStep("review");
  }, [deps]);

  const submit = useCallback(async (data: DraftData) => {
    setIsSaving(true);
    setErrorMessage(null);
    try {
      await deps.saveDraft(data);
      deps.onNavigateAway();
    } catch {
      setErrorMessage(MY_FEATURE_COPY.saveError); // extracted copy from configs/
    } finally {
      setIsSaving(false);
    }
  }, [deps]);

  return { step, isSaving, errorMessage, goToReview, submit };
}
```

The sub-hook:
- Receives **all side-effectful dependencies** through a typed `deps` parameter.
- Never imports from `api/`, `query/`, or platform modules (`expo-haptics`, `expo-router`, `@react-navigation/native`).
- Holds the React state machine, transitions, and error handling — the high-value behavior.
- Is the target of TDD.

### Thin wire-up hook (`useMyFeature.ts`)

```typescript
export function useMyFeature() {
  const { mutateAsync: saveDraft } = useSaveDraftMutation();
  const router = useRouter();

  const deps = useMemo(() => ({
    saveDraft: (data: DraftData) => saveDraft(data),
    validateForm: validateFormData,  // imported pure function from core/
    onNavigateAway: () => router.push("/dashboard"),
  }), [saveDraft, router]);

  return useMyFeatureState(deps);
}
```

The wire-up hook:
- Pulls in real deps (query mutations, navigation, platform APIs).
- Passes them to the testable sub-hook.
- Is intentionally untested.

### Tests (`useMyFeatureState.test.tsx`)

Use the custom `renderHook` harness (built on `react-test-renderer`):

```typescript
import { create, act } from "react-test-renderer";

type HarnessProps = { deps: UseMyFeatureStateDeps };

function renderHook(initialProps: HarnessProps) {
  let root: ReturnType<typeof create> | null = null;
  const bag = {
    results: [] as ReturnType<typeof useMyFeatureState>[],
    rerender(props: HarnessProps) {
      act(() => { root?.update(<Harness {...props} />); });
    },
    latest(): ReturnType<typeof useMyFeatureState> {
      return this.results[this.results.length - 1];
    },
    unmount() {
      act(() => { root?.unmount(); });
    },
  };

  function Harness(props: HarnessProps) {
    bag.results.push(useMyFeatureState(props.deps));
    return null;
  }

  act(() => { root = create(<Harness {...initialProps} />); });
  return bag;
}
```

Then test just like a pure function, but with `act()` for async state transitions:

```typescript
describe(useMyFeatureState.name, () => {
  it("should transition to review step when validation passes", async () => {
    const deps = { saveDraft: jest.fn(), validateForm: jest.fn().mockResolvedValue(true), onNavigateAway: jest.fn() };
    const { latest } = renderHook({ deps });

    await act(() => latest().goToReview({ ... }));
    expect(latest().step).toBe("review");
  });
});
```

### When a sub-hook fits

- The logic manages multi-step state (wizard, multi-page form, progressive disclosure)
- You need `useEffect`, `useRef`, or other React primitives that don't translate to a class
- The state transitions and side-effect orchestration are the high-value behavior worth testing

---

## Decision Guide

| Your logic... | Put it in... | Test it via... |
|---|---|---|
| Orchestrates sequential async steps with multiple data/API deps | `core/` class with `Deps` interface | Plain test doubles + direct instantiation |
| Transforms data with no side effects | Pure function in `app-logic/` (same file) or `core/` | Direct function call with plain objects |
| Needs React state, effects, or lifecycle | Testable sub-hook in `app-logic/` with DI params | Custom `renderHook` harness + `act()` |
| Is a thin wire-up that only assembles deps | Top-level hook in `app-logic/` exposed to pages | **Don't test it** |

## Rules

1. **The hook exposed to the page is always the thin wire-up.** It imports real deps (api/, query/, navigation), assembles them, and delegates. It is intentionally untested.

2. **The testable unit never imports from api/, query/, or platform modules.** Platform modules include `expo-haptics`, `expo-router`, `@react-navigation/native`, and any other Expo/React-Native-specific package. The testable unit receives everything it needs as parameters (constructor args, function args, or a deps object).

3. **Time is always injectable.** Never call `new Date()` inside the testable unit. Accept a `now: Date` parameter with a default.

4. **Mock at system boundaries only.** In tests, mock Firebase queries, navigation, and platform APIs. Never mock your own modules, classes, or hooks. (per `.claude/skills/tdd/mocking.md`)

5. **Test doubles are plain objects with tracking arrays.** Prefer `{ writes: [], commit: () => {} }` over `jest.fn()` for class tests. In sub-hook tests, assert **observable state transitions and return values** (e.g., `expect(result.current.step).toBe("review")`). A `toHaveBeenCalled*` matcher (`called` / `calledTimes` / `calledWith`) can never be a test's only claim — it is an implementation-detail assertion (see tdd skill anti-pattern: mock-call assertions). If the behavior is only visible through a dependency, assert the dependency's *outcome* via a tracking double (e.g., `expect(deps._batch.writes).toEqual([...])`), not the invocation itself; if you cannot observe the behavior without asserting the call, the seam is wrong — move the test to where the behavior is visible.

6. **One logical assertion per test.** Each test verifies one behavior. Use `describe(FunctionName.name, ...)` and `it("should ...", ...)` naming. (per `.claude/skills/tdd/SKILL.md`)

7. **Extract UI strings to configs.** Error messages, labels, and other copy live in feature `configs/` as copy objects. Don't inline strings in the testable unit. (per `docs/project-structure/CONTEXT.md` §Placement Decision Table)

## Anti-Patterns to Avoid

- **Fat hook that mixes wire-up and business logic in one function.** If your hook imports from `api/` or `query/` AND contains validation, classification, or decision logic, split it. Example: `useCreateSession.ts` in the codebase does both — it's a known instance that needs refactoring.
- **A fat `query/` hook.** A `useXQuery` that branches on input content (regex, prefix checks, format sniffing) is the same anti-pattern one layer over — the `query/` layer is thin definitions only (stable `queryKey` + one `queryFn` + `enabled` guard). Extract the branching rule to `services/core/` (test it there) and let an `app-logic/` hook activate the right thin query.

- **Testing the wire-up hook.** A test that renders the wire-up hook with mocked query hooks is tautological — it can never disagree with the implementation.

- **Mocking internal modules.** If you mock `useMyFeatureState` inside `useMyFeature`, you're testing wiring, not behavior. The sub-hook is tested separately; the wire-up is untested. Using `jest.mock("../../query/sessions")` in an app-logic test falls into this category.

- **Horizontal slicing.** Don't write all tests first, then all implementation. Work in vertical slices: one test → the minimal testable unit → repeat.

## Real Examples in This Codebase

| Pattern | Conforms? | Wire-up hook | Testable unit | Test file |
|---|---|---|---|---|
| A (class + DI) | ✅ | `useReplaceParticipant.ts` | `core/replaceParticipant.ts` (`ReplaceParticipant` class) | `core/replaceParticipant.test.ts` |
| A (class + DI) | ✅ | `useCreateReplacementInvite.ts` | `core/createReplacementInvite.ts` (`CreateReplacementInvite` class) | `core/createReplacementInvite.test.ts` |
| B (pure fn, same file) | ✅ | `useDashboardStats.ts` | `computeDashboardStats()` exported in same file | `useDashboardStats.test.ts` |
| B (pure fn in core) | ✅ | `useDashboardRawSessions.ts` | `core/mergeDashboardSessions.ts` | `useDashboardRawSessions.test.ts` |
| C (sub-hook + DI) | ⚠️ partial | `useCreateSessionWizard.ts` | *(DI for `form` + `onNavigateAway`, but directly imports `expo-haptics` + `@react-navigation/native`)* | `useCreateSessionWizard.test.tsx` |

### Non-conforming example

`useCreateSession.ts` mixes wire-up (imports `useCreateSessionMutation` from `query/`) and business logic (date transforms, input conversion, error handling) in one function. Its test uses `jest.mock("../../query/sessions")`. This is the anti-pattern described above and a candidate for refactoring into Pattern A or C.

---

> **In case of conflict**, `docs/*/CONTEXT.md` takes highest precedence, then ADRs, then `CLAUDE.md`, then this guide.
