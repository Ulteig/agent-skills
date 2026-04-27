# SOLID + DRY Review Checklist

## SOLID

### SRP (Single Responsibility)
- Classes/modules doing unrelated jobs
- Methods handling orchestration + domain logic + persistence together
- Multiple reasons to change in one component

### OCP (Open/Closed)
- New behavior requires editing core branching logic repeatedly
- No extension points (strategy/policy/plugin) where variation is expected

### LSP (Liskov Substitution)
- Subtypes break caller assumptions
- Overridden methods throw for valid base cases
- Type checks used instead of polymorphism

### ISP (Interface Segregation)
- Large interfaces with methods unused by implementers
- Consumers forced to depend on methods they do not need

### DIP (Dependency Inversion)
- Business logic coupled to concrete infrastructure classes
- Hard-coded dependency creation instead of abstraction/injection

## DRY

- Repeated business rules across files/services
- Duplicated validation logic
- Copy-pasted mapping/transformation code
- Repeated literals, magic strings, and constants
- Similar queries or API calls implemented multiple times

## Refactor Guidance

- Prefer small, safe extraction over large rewrites
- Consolidate duplicated logic behind domain-level abstractions
- Preserve behavior with tests before/after refactors
