# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- **Any `toHaveBeenCalled` / `toHaveBeenCalledTimes` / `toHaveBeenCalledWith` matcher as the test's only claim — always implementation-detail; a mock invocation is never observable behavior. Hard ban: such a matcher can never stand alone. Applies to tests touched by the diff; pre-existing mock-call-only tests in untouched files are migration debt (🟡).**
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**Wrong-seam tests**: The seam itself is wrong — behavior is invisible at that layer, so the test can only assert mock mechanics.

```typescript
// BAD: completeSession wraps a Firestore transaction; asserting its mock calls tests nothing observable
test("completeSession runs a transaction and writes the log", async () => {
  await completeSession(sessionId);
  expect(runTransaction).toHaveBeenCalled();
  expect(updateDoc).toHaveBeenCalledTimes(2);
});
```

If all a test asserts is mock call arguments, the seam is wrong. Move the test to where the behavior lives — `services/core/` (pure) or `services/app-logic/` (mock the thin API layer at the cross-module boundary) — or replace it with an emulator integration test.

**Tautological tests**: Expected value restates the implementation, so the test passes by construction.

```typescript
// BAD: Expected value is recomputed the way the code computes it
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: Expected value is an independent, known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```

**Context-leaning descriptions**: A description that only makes sense next to a ticket, PR, issue, or file name — instead of standing alone as a statement of behavior.

```typescript
// BAD: Meaningless once the ticket is archived or the PR is merged
it("should fix the bug reported in #487", () => {});
it("should match ticket 102 requirements", () => {});
it("should behave like SessionStatusBanner.tsx expects", () => {});

// GOOD: Names the behavior itself, no outside context required
it("should mark a session late when a due cycle has no approved contribution", () => {});
```

A test description is documentation that outlives the ticket that prompted it. If understanding the description requires going to read something else first, the description has failed at its one job. (Mechanically enforced for tickets/PRs/issues/file names by the `local/test-description-self-contained` ESLint rule; paraphrased context-leaning phrasing is a reviewer judgment call.)
