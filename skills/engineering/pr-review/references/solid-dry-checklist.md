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
