# SOLID + DRY Review Checklist

## SOLID

### SRP (Single Responsibility)
- Flag: Classes/modules doing unrelated jobs
- Flag: Methods handling orchestration + domain logic + persistence together
- Flag: Controllers or UI components that hold business logic
- Flag: Files or components that keep growing (suggest sub-components or a service)
- Flag: Several classes or components in one file
- Flag: Multiple reasons to change in one component

### OCP (Open/Closed)
- Flag: New behavior requires editing core branching logic repeatedly
- Flag: No extension points (strategy/policy/plugin) where variation is expected

### LSP (Liskov Substitution)
- Flag: Subtypes break caller assumptions
- Flag: Overridden methods throw for valid base cases
- Flag: Type checks used instead of polymorphism

### ISP (Interface Segregation)
- Flag: Large interfaces with methods unused by implementers
- Flag: Consumers forced to depend on methods they do not need

### DIP (Dependency Inversion)
- Flag: Business logic coupled to concrete infrastructure classes
- Flag: Hard-coded dependency creation instead of abstraction/injection
- Flag: Skipping the repo's documented layers (for example a controller or service using the database context directly instead of the unit of work or repository the repo uses)
- Flag: New code on a legacy pattern the repo is moving away from (check `AGENTS.md`, ADRs, and neighboring code)

## DRY

- Flag: Repeated business rules across files/services
- Flag: Duplicated validation logic
- Flag: Copy-pasted mapping/transformation code
- Flag: Repeated literals, magic strings, and constants
- Flag: Similar queries or API calls implemented multiple times
- Flag: The same block repeated several times with one value changed (drive it from data or a function)
- Flag: If/else branches where only one argument differs
- Flag: Copied helpers or models (check for an existing equivalent, and move shared code to the shared project)
- Flag: A new query that extends an existing one, which fetches extra fields. Prefer a narrow new query
- Review: For every new reusable component/class/etc, grep the repo for an existing thing that already does this; prefer extending it.

## Behavior Placement

- Expected: Ensure that methods are attached to the correct object. Logic that only reads or validates one object's data belongs on that object.

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
- Expected: Prefer small, safe extraction over large rewrites
- Expected: Consolidate duplicated logic behind domain-level abstractions
- Expected: Preserve behavior with tests before/after refactors
