# Naming Checklist

A good name describes the role of code in the domain.
Read the name at a call site.
Example: `if (user.canEdit(document))` describes the problem.
Example: `if (checkPerm(list[i], d))` describes implementation details.

Follow language idioms.
Example: Go and Rust getters omit `get`.
Example: C# properties use nouns.
Example: React handlers use `handleX` or `onX`.

## Grammar by construct

| Construct | Shape | Good | Flag |
|---|---|---|---|
| Function / method | Action verb phrase | `sendInvoice`, `calculateTotal`, `findActiveUsers` | `invoice()`, `totals()`, `userLookup()` |
| Boolean | Predicate | `isActive`, `hasAccess`, `canRetry`, `shouldNotify` | `active`, `flag`, `status`, `check` |
| Collection | Plural domain noun | `users`, `pendingOrders` | `list`, `items`, `arr`, `userList` |
| Map / dictionary | Value by key | `usersById`, `priceBySku` | `map`, `dict`, `lookup`, `userMap` |
| Class / type | Domain noun | `Invoice`, `RetryPolicy` | `InvoiceManager`, `DataHelper`, `Utils` |
| Variable / field / parameter | Domain noun | `customer`, `retryDelayMs` | `data`, `obj`, `val`, `tmp`, `result` |

## Domain over representation

Use domain names instead of representation names.
The type defines the storage; the name defines the meaning.
Use `users`, not `list` or `userArray`.

Do not use type-encoding words:
`list`, `array`, `map`, `dict`, `str`, `obj`, `strName`, `userObj`, `orderDto` (except in DTO layers).

Do not use filler words:
`data`, `info`, `item`, `value`, `thing`, `stuff`, `manager`, `helper`, `util`, `handler`, `process`, `do`, `perform`.

Use representation words only when the representation is the purpose.
Example: `invoiceJson` (at a serialization boundary) or `rawBytes` (in a codec).

## Vocabulary consistency

- Use one word for one concept.
  Check the codebase (including `GLOSSARY.md`, `CONTEXT.md`, or ADRs) for existing terms.
  Example: Use `customer` if the codebase already uses `customer`.
- Use one verb for one operation.
  Example: Do not mix `fetch`, `get`, and `load` for the same operation.

## Honesty

- Names must match the implementation.
  A name that lies is a finding.
  Example: `getUser` should not create a user.
  Example: `validate` should not mutate state.
  Example: `isReady` should not have side effects.
- Include units and absence in the name where important.
  Example: Use `timeoutMs`.
  Example: Use `findUser` if the function can return nothing.
  Example: Use `getUser` if the function throws when a user is missing.

## Scope and length

- Scale name length with scope.
  A short name like `i` is acceptable in a small loop.
  A short name like `i` is a finding if it is a class field.
- Use abbreviations only for universal domain terms.
  Example: `id`, `url`, `sku`.
  Private abbreviations like `custMgr` are findings.

## Severity and reporting

- **P2 Medium**: The name is dishonest.
  OR the name is part of a public API, a route, a database column, or any published data where a rename is a breaking change.
- **P3 Low**: All other naming findings.

Tag findings with `Naming`.
Include the following for each finding:
1. The identifier name.
2. The rule it breaks.
3. A replacement name.
