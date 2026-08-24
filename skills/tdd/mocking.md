# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes - prefer test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

**Cross-module boundaries are system boundaries.** From one module's perspective, another module is external — mocking `createNotification` from `@/modules/notifications/` inside a `ledger` test is legitimate. Mocking a sibling file (`./activityLogs`) is not; that's an internal collaborator.

**Skip unit tests for thin `api/firebase/` files.** They mostly wrap the Firebase SDK, so a unit test reduces to asserting `runTransaction`/`doc`/`updateDoc` call arguments — implementation-coupled. A truly thin function (params in, Firestore call, result out) is better served by an integration test against the emulators. Test `services/core/` (pure) and `services/app-logic/` (mock the API layer at the cross-module boundary) instead.

**Even at a legitimate boundary mock, a `toHaveBeenCalled*` matcher can never be a test's only claim.** Assert the observable outcome of the call (the state the call produces, the data returned, the rendered result) or the double's tracked outcome (`expect(deps._batch.writes).toEqual([...])`); assert the invocation only as supplementary evidence, never alone.

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch("/orders", { method: "POST", body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means:

- Each mock returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint
