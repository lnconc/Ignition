# Function Overloading
In standard Luau, if you want a function to handle different types of input, you have to write a massive `if-elseif` chain inside the function body. Ignition automates this using **Overload Records.**

## How it works
You use the `import` helper to *"sign"* your implementation. By passing a `table` (the signature) to `import`, you tell Ignition: *"Only run this function if the arguments match these types."*

### Basic Overloading
You can define multiple implementations for the same method name.
```luau
-- MyClass.luau (Implementation)
local MyClass = import()

-- Overload 1: Takes a string
MyClass {"string"} ("Greet") (function(self, name)
    print("Hello, " .. name)
end)

-- Overload 2: Takes a number
MyClass {"number"} ("Greet") (function(self, amount)
    print("Hello x" .. amount)
end)

-- Fallback: Runs if no signature matches
function MyClass:Greet()
    print("Hello to everyone!")
end
```

### Complex Types: `nullable` and `union`
Ignition provides helpers to handle more flexible signatures.

* **`nullable(type)`:** Matches the specific type or nil.
* **`union(...types)`:** Matches any of the provided types.

```luau
local nullable = Ignition.nullable
local union = Ignition.union

-- Matches: string OR nil
MyClass {nullable("string")} ("SetName") (function(self, name)
    self._name = name or "Default"
end)

-- Matches: number OR boolean
MyClass {union("number", "boolean")} ("SetStatus") (function(self, value)
    self._status = value
end)
```

## The Dispatch Logic
When an overloaded method is called, Ignition's `getOverloadedFunction` performs a three-step check:

1. **Exact Match:** It first checks a hash map of simple type strings (e.g., `"string,number"`). This is extremely fast.
2. **Complex Match:** If no exact match is found, it iterates through *"Complex"* signatures (those using `union` or `nullable`) to find a logical match.
3. **Fallback:** If all else fails, it runs the `fallback` function. If no `fallback` exists, it throws a `NO_OVERLOAD_MATCH` error.

!!! warning "Signatures vs. Callbacks"
    Ensure the number of elements in your signature table matches the number of parameters the function expects (excluding `self`).
    ```luau
    -- Expects 2 args: number and string
    MyClass {"number", "string"} ("Update") (function(self, id, name) ... end)

## Overloading the Constructor
You can even overload the class `constructor`! This allows you to create objects in multiple ways.
```luau
-- Constructor 1: Empty
impl {} (function(self)
    self.Data = {}
end)

-- Constructor 2: With initial data
impl {"table"} (function(self, initialData)
    self.Data = initialData
end)
```