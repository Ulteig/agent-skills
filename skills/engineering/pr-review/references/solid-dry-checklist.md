# SOLID + DRY Review Checklist

## SOLID

### SRP (Single Responsibility)
- Classes/modules doing unrelated jobs
- Methods handling orchestration + domain logic + persistence together
- Controllers or UI components that hold business logic
- Files or components that keep growing (suggest sub-components or a service)
- Several classes or components in one file
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
- Skipping the repo's documented layers (for example a controller or service using the database context directly instead of the unit of work or repository the repo uses)
- New code on a legacy pattern the repo is moving away from (check `AGENTS.md`, ADRs, and neighboring code)

## DRY

- Repeated business rules across files/services
- Duplicated validation logic
- Copy-pasted mapping/transformation code
- Repeated literals, magic strings, and constants
- Similar queries or API calls implemented multiple times
- The same block repeated several times with one value changed (drive it from data or a function)
- If/else branches where only one argument differs
- Copied helpers or models (check for an existing equivalent, and move shared code to the shared project)
- A new query that extends an existing one, which fetches extra fields. Prefer a narrow new query
- For every new reusable component/class/etc, grep the repo for an existing thing that already does this; prefer extending it.

## Behavior Placement

- Ensure that methods are attached to the correct object. Logic that only reads or validates one object's data belongs on that object.

```csharp
// Wrong: validation of the request lives on the solver
public class NewtonSolverRequest
{
    // properties..
}
public class NewtonSolver
{
    public void Validate(NewtonSolverRequest request)
    {
        if (/* not valid.. */)
        {
            throw /* exception.. */;
        }
    }
}
```

```csharp
// Right: the request validates itself
public class NewtonSolverRequest
{
    // properties..
    public void Validate()
    {
        if (/* not valid.. */)
        {
            throw /* exception.. */;
        }
    }
}
public class NewtonSolver
{
}
```

## Refactor Guidance
- Prefer small, safe extraction over large rewrites
- Consolidate duplicated logic behind domain-level abstractions
- Preserve behavior with tests before/after refactors
