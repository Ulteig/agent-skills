# Best Practices Checklist for PR Reviews

## React
- Only use `useEffect` when synchronizing with an external system
  - `useEffect` + single `useState` should become `useMemo`
  - `useEffect` to handle events should instead just use those events (e.g. `onClick` handler instead of `useEffect` reacting to something)
  - The core rule of modern React development is to use useEffect only as an escape hatch to synchronize with external systems. According to the Official React Documentation, if your logic is not connecting to an external API, a browser API, a subscription, or a third-party widget, you likely do not need an effect.
  - State that mirrors a prop, or a timer used where a direct fetch works, is a smell
- List `key` is a stable ID from the data, never the array index or a value that changes per render
- Set state only through the setter, never by mutating it directly
- Check effect dependency arrays for missing values
- New components are function components, not classes
- Callback props are named `onX` (`onDeleteConfirmed`), and a prop that is already a callback needs no second callback
- Do not wrap an existing component only to restyle it: the wrapper removes power. Avoid prop shapes like `pageObj` / `setPageObj` / `objKey` that make a child own a copy of parent state
- Avoid `keyof T` strings for state updates: rename refactors do not update them
- Generic components (charts, inputs) take project-specific parts as props, not hard-coded
- Context lives at the level where it is valid. Do not expose it on pages where it has no meaning, and do not push it down through props when a provider exists
- Components that are very long, or that repeat the same JSX with one value changed, should be split or driven by data
- Complex inline logic or long ternaries move to a named function

## Magic Values
- No bare numbers or strings whose meaning is hidden (`1`, `6`, `8`, `report[1]`, `-1`, `43560`, `"--"`, `"Not Entered"`). Use an enum, a named constant, or a lookup
- Do not compare on display text. Compare on an ID or enum
- Do not hard-code a lookup value (such as "1 is wet") when the database or lookups can change it
- Do not reuse or renumber existing lookup IDs: stored data would change meaning
- A flag with two non-obvious states (`sortedDirection: bool`) should be an enum or string literal
- Use a bool or int, not a string, for true/false and status data
- Colors, sizes, and z-index values come from global styles or one config, not each component. Check z-index against what it must sit above

## Data and API Design
- Filtering and sorting happen in the API or database, not after fetching everything to the client
- Business logic does not live in a controller or UI component. Put it in a service, or in a shared core project if several places need it
- Identifiers are IDs, not names. Dates are typed as dates, not strings
- Model nullability matches the database. Do not make a required column optional, and do not mark a non-null return as nullable (or the reverse)
- Return type matches storage behavior: if the lookup throws when missing, do not return a nullable
- Throw on invalid input (such as a negative ID) instead of returning `0` or `null` silently
- Null-check an entity before update or delete
- Make hard delete vs soft delete explicit
- A POST sends a body, not query parameters
- Caching is safe only for data that cannot change (for example immutable records)
- A new endpoint keeps its authorization. Do not drop `[Authorize]`, and do not repeat it where a base class already applies it

## Correctness and Reliability
- Boundary checks for null/empty/invalid input
- Consistent error handling (no swallowed exceptions)
- A `try/catch` that does nothing with the exception should be removed when the framework already handles it
- Proper retry/timeout/circuit-breaker behavior where needed
- Backward compatibility and migration safety
- Arithmetic on IDs (`.Id + 1`) followed by `.First()` assumes ordered, gapless IDs and throws when it fails
- Bitwise vs logical operators (`|` where `||` was meant), and a function reference or call that is missing its `()`
- Avoid `out` / `ref` parameters and `bool` + out list: return the value. They also block async
- Ask what happens when input is already in the target form, or is neither of two expected cases
- Check the effect of a status or filter change on every other caller

## Migrations, Config, and Repo Hygiene
- Never hand-edit a migration that has already shipped. Do not delete migrations. Treat both as P1
- A snapshot change must come with a migration
- Check for migrations already in the base branch or other open PRs (ordering and conflicts)
- No hard-coded database names, hosts, `localhost`, ports, or environments. Config differs between dev, QA, and prod
- Defaults in `appsettings`, `launchSettings`, and `config` files must not point at prod or carry local-only changes
- For any new key or credential, ask what it can access
- No stray files: editor temp files, coverage output, wrong-folder lockfiles, encoding-only churn
- No changes unrelated to the ticket (from another branch or a find-and-replace). Ask whether they are intended
- When code is removed, confirm nothing else uses it
- A dependency already available through another package should not be added again

## Maintainability
- Clear module boundaries
- Avoid unnecessary complexity and deep nesting (invert `if` to return early)
- Good cohesion and low coupling
- Avoid dead code and speculative abstractions
- No commented-out code, `console.log`, unused imports, or `TODO` without a ticket. Commented-out placeholder data should be real dummy data
- Do not leave known framework warnings that the PR touches

## Performance
- N+1 query patterns
- Repeated expensive work without caching/batching
- Unbounded memory/data loading
- Heavy synchronous work on hot paths
- EF Core queries with many `Include`s need `AsSplitQuery()`
- Materialize once: avoid repeated `ToList()`, and avoid a second `ToList()` on a list
- Use `any()` instead of `count()` for existence checks
- Do not fetch whole tables or extra columns. Add a narrow query for the use case
- Return `IEnumerable` when callers only read

## Testing and Verification
- New behavior covered by tests
- Regressions guarded by unit/integration tests. A bug fix includes a test that would have caught it
- Edge cases and failure paths tested
- A test must be able to fail. Do not use the same value everywhere, make the test data differ so a wrong answer shows up
- Test the boundary value once (`-1`), not redundant neighbors (`0` and `1`)
- No duplicate tests. Add the missing case (for example a null result)
- Do not unit test behavior that lives in the database query (an `active` filter) at the service level
- One test file per method under test, or at least no method name in the file name. Namespace matches the folder

## Observability
- Actionable logs with context (without leaking secrets)
- Useful metrics/tracing for critical paths
- Failures are detectable and diagnosable
- A user-facing failure shows a clear message, not a silent `console.log`

## Comments
- Comments that explain the PR/ticket rather than the code (they go stale the moment the PR merges)
- Ticket/issue numbers embedded in code
- Comments restating what the code already says
- Important info in a `//` line that should be a doc comment

## Documentation
- PR description explains intent and risk
- Any behavior/config changes are documented
- Follow-up items are called out explicitly (and have a ticket)
