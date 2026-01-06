# Operator Overloading
To make your class interact with math or logic operators, you must define the corresponding metamethod in your header and provide an implementation.

## Defining the Operator
In your header file (`.definition.luau`), you define an operator by assigning it the `METADATA` symbol. This tells Ignition: *"I intend to use this metamethod, but don't treat it as a standard data property."*

```luau
-- Vector.definition.luau
return class "Vector"  {
    public = {
        X = 0,
        Y = 0,
        -- Declare that this class supports addition
        __add = METADATA,
        __tostring = METADATA,
    }
}
```

## Implementation
In your implementation file, use the `import` helper to define the logic for the operator just like a normal function.

```luau
-- Vector.luau
local Vector = import()

Vector.__add = function(self, other)
    return new(Vector)(self.X + other.X, self.Y + other.Y)
end

Vector.__tostring = function(self)
    return `Vector({self.X}, {self.Y})`
end
```

## Supported Operators
Ignition supports the standard suite of Luau metamethods:

| Operator | Metamethod | Description |
| --- | --- | --- |
| `+` | `__add` | Addition |
| `-` | `__sub` | Subtraction |
| `*` | `__mul` | Multiplication |
| `/` | `__div` | Division |
| `..` | `__concat` | Concatenation |
| `#` | `__len` | Length operator |
| `==` | `__eq` | Equality |
| `<`, `>` | `__lt` | Less/Greater than |
| `<=`, `>=` | `__le` | Less/Greater than or equal to |
| `for ... in ... do` | `__iter` | Iteration |
| `()` | `__call` | Calling the object as a function |
| `print()`, `tostring()` | `__tostring` | String representation |

## Visibility & Security
One of Ignition's unique features is that **operators can have visibility levels.**

* **Public Operators:** The most common. Anyone can add two of your objects together.
* **Private/Protected Operators:** If you define an operator inside the `private` table, only the class itself can use that operator.

If an external script tries to use a `private` operator, Ignition's `encapsulate` logic will catch the access violation via the `StackSpider` and throw an `OPERATOR_VIOLATION` error.
``` luau
-- Only this class can use the length operator on itself
private = {
    __len = METADATA
}
```

!!! danger "Zombies & Operators"
    If you call an operator on an object that has been `delete()`-ed, Ignition will throw a `DESTROYED_OP` error. During the destruction process, all operator slots are replaced with a poisoned function to prevent stale math logic from corrupting your game state.