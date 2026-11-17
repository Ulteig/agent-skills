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

- Expected: Use one word for one concept.
  Check the codebase (including `GLOSSARY.md`, `CONTEXT.md`, or ADRs) for existing terms.
  Example: Use `customer` if the codebase already uses `customer`.
- Expected: Use one verb for one operation.
  Example: Do not mix `fetch`, `get`, and `load` for the same operation.

## Distinguishing names

- Expected: A number is not a distinguishing word. Flag `TableComponent2`, `Table5ViewModel`, `invoice2`. Name what differs (`previousInvoice`).
- Flag: Version suffixes (`V5`, `V6`) are a finding unless the version is the domain.
- Flag: Names that are too generic for their scope: `TableService`, `HelperClass`, `Single`, `Dummy`, `Limited`. Ask "which table, for what purpose?"
- Expected: Order a family of names from least specific to most specific (like `yyyy-mm-dd`), so related names sort together.
- Expected: A file name matches the main component or class in it. A component name matches its siblings (do not add `Form` to one of many).
- Expected: Follow the prefix convention of the parent (`RrProjectTransferAgreementX` stays `RrProject...`).
- Expected: A collection (including a database set) is plural. A name that says `list` or `many` should return many (do not use a list for "at most one").
- Expected: An id property says what it is: `municipalityId`, not `municipality`. Do not mix `userId` and `authId` for one concept.
- Expected: Casing: PascalCase for types and enums, camelCase for locals and members. Do not put the construct in the name (`enumFoo`).
- Expected: A class name is a noun (`ShpExtractor`, not `ExtractShps`).
- Expected: A name must not hide a side effect: a "check" that also sets is a finding.

## Honesty

- Expected: Names must match the implementation.
  A name that lies is a finding.
  Example: `getUser` should not create a user.
  Example: `validate` should not mutate state.
  Example: `isReady` should not have side effects.
- Expected: Include units and absence in the name where important.
  Example: Use `timeoutMs`.
  Example: Use `findUser` if the function can return nothing.
  Example: Use `getUser` if the function throws when a user is missing.

## Scope and length

- Expected: Scale name length with scope.
  A short name like `i` is acceptable in a small loop.
  A short name like `i` is a finding if it is a class field.
- Expected: Use abbreviations only for universal domain terms.
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
