# Best Practices Checklist for PR Reviews

## React
- Only use `useEffect` when synchronizing with an external system
  - `useEffect` + single `useState` should become `useMemo`
  - `useEffect` to handle events should instead just use those events (e.g. `onClick` handler instead of `useEffect` reacting to something)
  - The core rule of modern React development is to use useEffect only as an escape hatch to synchronize with external systems. According to the Official React Documentation, if your logic is not connecting to an external API, a browser API, a subscription, or a third-party widget, you likely do not need an effect.

## Correctness and Reliability
- Boundary checks for null/empty/invalid input
- Consistent error handling (no swallowed exceptions)
- Proper retry/timeout/circuit-breaker behavior where needed
- Backward compatibility and migration safety

## Maintainability
- Clear naming and module boundaries
- Avoid unnecessary complexity and deep nesting
- Good cohesion and low coupling
- Avoid dead code and speculative abstractions

## Performance
- N+1 query patterns
- Repeated expensive work without caching/batching
- Unbounded memory/data loading
- Heavy synchronous work on hot paths

## Testing and Verification
- New behavior covered by tests
- Regressions guarded by unit/integration tests
- Edge cases and failure paths tested

## Observability
- Actionable logs with context (without leaking secrets)
- Useful metrics/tracing for critical paths
- Failures are detectable and diagnosable

## Documentation
- PR description explains intent and risk
- Any behavior/config changes are documented
- Follow-up items are called out explicitly
