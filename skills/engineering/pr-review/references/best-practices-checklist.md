# Best Practices Checklist for PR Reviews

## React
- Expected: Only use `useEffect` when synchronizing with an external system
  - Expected: `useEffect` + single `useState` should become `useMemo`
  - Expected: `useEffect` to handle events should instead just use those events (e.g. `onClick` handler instead of `useEffect` reacting to something)
  - Expected: The core rule of modern React development is to use useEffect only as an escape hatch to synchronize with external systems. According to the Official React Documentation, if your logic is not connecting to an external API, a browser API, a subscription, or a third-party widget, you likely do not need an effect.
  - Flag: State that mirrors a prop, or a timer used where a direct fetch works, is a smell
- Expected: List `key` is a stable ID from the data, never the array index or a value that changes per render
- Expected: Set state only through the setter, never by mutating it directly
- Review: Check effect dependency arrays for missing values
- Expected: New components are function components, not classes
- Expected: Callback props are named `onX` (`onDeleteConfirmed`), and a prop that is already a callback needs no second callback
- Expected: Do not wrap an existing component only to restyle it: the wrapper removes power. Avoid prop shapes like `pageObj` / `setPageObj` / `objKey` that make a child own a copy of parent state
- Expected: Avoid `keyof T` strings for state updates: rename refactors do not update them
- Expected: Generic components (charts, inputs) take project-specific parts as props, not hard-coded
- Expected: Context lives at the level where it is valid. Do not expose it on pages where it has no meaning, and do not push it down through props when a provider exists
- Expected: Components that are very long, or that repeat the same JSX with one value changed, should be split or driven by data
- Expected: Complex inline logic or long ternaries move to a named function

## Magic Values
- Expected: No bare numbers or strings whose meaning is hidden (`1`, `6`, `8`, `report[1]`, `-1`, `43560`, `"--"`, `"Not Entered"`). Use an enum, a named constant, or a lookup
- Expected: Do not compare on display text. Compare on an ID or enum
- Expected: Do not hard-code a lookup value (such as "1 is wet") when the database or lookups can change it
- Expected: Do not reuse or renumber existing lookup IDs: stored data would change meaning
- Expected: A flag with two non-obvious states (`sortedDirection: bool`) should be an enum or string literal
- Expected: Use a bool or int, not a string, for true/false and status data
- Expected: Colors, sizes, and z-index values come from global styles or one config, not each component. Check z-index against what it must sit above

## Data and API Design
- Expected: Filtering and sorting happen in the API or database, not after fetching everything to the client
- Expected: Business logic does not live in a controller or UI component. Put it in a service, or in a shared core project if several places need it
- Expected: Identifiers are IDs, not names. Dates are typed as dates, not strings
- Expected: Model nullability matches the database. Do not make a required column optional, and do not mark a non-null return as nullable (or the reverse)
- Expected: Return type matches storage behavior: if the lookup throws when missing, do not return a nullable
- Expected: Throw on invalid input (such as a negative ID) instead of returning `0` or `null` silently
- Expected: Null-check an entity before update or delete
- Expected: Make hard delete vs soft delete explicit
- Expected: A POST sends a body, not query parameters
- Expected: Caching is safe only for data that cannot change (for example immutable records)
- Expected: A new endpoint keeps its authorization. Do not drop `[Authorize]`, and do not repeat it where a base class already applies it

## Correctness and Reliability
- Expected: Boundary checks for null/empty/invalid input
- Expected: Consistent error handling (no swallowed exceptions)
- Expected: A `try/catch` that does nothing with the exception should be removed when the framework already handles it
- Expected: Proper retry/timeout/circuit-breaker behavior where needed
- Expected: Backward compatibility and migration safety
- Flag: Arithmetic on IDs (`.Id + 1`) followed by `.First()` assumes ordered, gapless IDs and throws when it fails
- Flag: Bitwise vs logical operators (`|` where `||` was meant), and a function reference or call that is missing its `()`
- Expected: Avoid `out` / `ref` parameters and `bool` + out list: return the value. They also block async
- Review: Ask what happens when input is already in the target form, or is neither of two expected cases
- Review: Check the effect of a status or filter change on every other caller

## Migrations, Config, and Repo Hygiene
- Expected: Never hand-edit a migration that has already shipped. Do not delete migrations. Treat both as P1
- Expected: A snapshot change must come with a migration
- Review: Check for migrations already in the base branch or other open PRs (ordering and conflicts)
- Expected: No hard-coded database names, hosts, `localhost`, ports, or environments. Config differs between dev, QA, and prod
- Expected: Defaults in `appsettings`, `launchSettings`, and `config` files must not point at prod or carry local-only changes
- Review: For any new key or credential, ask what it can access
- Expected: No stray files: editor temp files, coverage output, wrong-folder lockfiles, encoding-only churn
- Expected: No changes unrelated to the ticket (from another branch or a find-and-replace). Ask whether they are intended
- Review: When code is removed, confirm nothing else uses it
- Expected: A dependency already available through another package should not be added again

## Maintainability
- Expected: Clear module boundaries
- Expected: Avoid unnecessary complexity and deep nesting (invert `if` to return early)
- Expected: Good cohesion and low coupling
- Expected: Avoid dead code and speculative abstractions
- Expected: No commented-out code, `console.log`, unused imports, or `TODO` without a ticket. Commented-out placeholder data should be real dummy data
- Expected: Do not leave known framework warnings that the PR touches

## Performance
- Flag: N+1 query patterns
- Flag: Repeated expensive work without caching/batching
- Flag: Unbounded memory/data loading
- Flag: Heavy synchronous work on hot paths
- Expected: EF Core queries with many `Include`s need `AsSplitQuery()`
- Expected: Materialize once: avoid repeated `ToList()`, and avoid a second `ToList()` on a list
- Expected: Use `any()` instead of `count()` for existence checks
- Expected: Do not fetch whole tables or extra columns. Add a narrow query for the use case
- Expected: Return `IEnumerable` when callers only read

## Testing and Verification
- Expected: New behavior covered by tests
- Expected: Regressions guarded by unit/integration tests. A bug fix includes a test that would have caught it
- Expected: Edge cases and failure paths tested
- Expected: A test must be able to fail. Do not use the same value everywhere, make the test data differ so a wrong answer shows up
- Expected: Test the boundary value once (`-1`), not redundant neighbors (`0` and `1`)
- Expected: No duplicate tests. Add the missing case (for example a null result)
- Expected: Do not unit test behavior that lives in the database query (an `active` filter) at the service level
- Expected: One test file per method under test, or at least no method name in the file name. Namespace matches the folder

## Observability
- Expected: Actionable logs with context (without leaking secrets)
- Expected: Useful metrics/tracing for critical paths
- Expected: Failures are detectable and diagnosable
- Expected: A user-facing failure shows a clear message, not a silent `console.log`

## Comments
- Flag: Comments that explain the PR/ticket rather than the code (they go stale the moment the PR merges)
- Flag: Ticket/issue numbers embedded in code
- Flag: Comments restating what the code already says
- Flag: Important info in a `//` line that should be a doc comment

## Documentation
- Expected: PR description explains intent and risk
- Expected: Any behavior/config changes are documented
- Expected: Follow-up items are called out explicitly (and have a ticket)
