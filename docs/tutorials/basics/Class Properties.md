# Class Properties

Now that we know there is a helper function called `func`, you might ask if there must be something similar for properties?

Properties are the state of your class. In Ignition, you can define properties simply by assigning values, or by using the `property` helper for more control over visibility, function, and type safety.

## The Basics
In your header file, properties are defined inside the `public`, `protected`, or `private` tables *(or as taught in [Classes and Objects](./Classes and Objects.md), the `fields` structure itself, as it is inferred as a `public` field)*.

``` luau
-- PlayerData.definition.luau
return class("PlayerData") {
    public = {
        DisplayName = "Guest", -- A simple public property
        Level = 1,
    },
    private = {
        _internalId = 0, -- Only accessible within this class
    }
}
```

### Simple vs. Managed
* **Simple Assignment (`key = value`):** Just set a key to a value. Ignition treats this as a standard property with no special rules.
* **Managed (via `property`):** Use the `property` function to add metadata like **Exposure** (Server/Client filtering) or **Flags.**

### The `property` Helper
Much like to `func`, the `property` function allows you to define how a property behaves across the network and how it interacts with Ignition's runtime checks.

**Usage Example:**
``` luau
public = {
    -- This property only exists on the Server
    SecretToken = property({
        value = "XYZ-123", -- For illustration only; realistically, you'd have the `constructor` do this.
        from = "server"
    }),

    -- This property exists everywhere
    Score = property({
        value = 0,
        from = "shared",
        type = "number" :: "number"
    })
}
```

!!! question "Why am I seeing `"number" :: "number"`?"
    Roblox often widens singletons as strings when made as a generic. If you write `type = "number"`, Luau might just see the type `string`. To ensure the Type Solver knows exactly what you mean, cast the string to a singleton:
    ``` luau
    -- Force the solver to see the specific "number" type
    Age = property({
        value = 25,
        type = "number" :: "number" 
    })
    ```

!!! tip "Ghost Typing"
    If you want the Type Solver to know the type, but you **do not** want Ignition to spend performance on runtime type-checking (`encapsulate/upsert`), you can cast `nil` to the target type. This tells the solver *"this is a number"* while telling the runtime *"don't check this."*
    ``` luau
    -- Type Solver sees a number, Runtime skips the check
    XP = property({
        value = 100,
        type = nil :: "number" 
    })
    ```

The `property` helper accepts an options table:

* **`value`:** The initial value of the property.
* **`type`:** An optional configuration that is used for runtime type checking.
* **`exposure`:** Defines if the property exists on the `"client"`, `"server"`, or `"shared"`. If the network environment doesn't match, the property is never even defined.
* **`flags`:** Optional modifiers like `FLAGS.Readonly` or `FLAGS.Constant`.

## Special Property Types: `METADATA` and `PLACEHOLDER`
1. **Metadata (`METADATA`):**
Properties tagged with the `METADATA` symbol are not added to the object's data fields. They are stripped during instantiation but remain accessible for reading.
    * **Use Case:** Versioning, adding ghost properties, or configuring custom metamethods.

2. **Placeholders (`PLACEHOLDER`):**
A `PLACEHOLDER` property is added to the object's data field, but it signals that the value will be populated **later** (usually by the `constructor` or an external service).
    * **Use Case:** Storing a reference to a Roblox `Instance` (like a `Part`) or a `RemoteEvent`, `Signals` or `Connections`, or other instantiable instances that is created at runtime.

**Usage Example:**
``` luau
return class "PlayerCombat" {
    public = {
        -- Metadata: Exists in the Registry, but not on the 'self' data table
        Version = METADATA {
            Version = "1.2.0",
            Description = "Handles player combat logic"
        },

        -- Placeholder: Space is reserved on 'self', but value starts as nil/placeholder
        OnHit = property({
            value = PLACEHOLDER,
            type = "any" :: Signal
        })
    }
}
```

## Flags
Flags are symbols used to modify the behavior of class members. They are primarily used within the `property` and `func` helpers to tell Ignition how to handle that member during runtime.

| Flag | Description |
| --- | --- |
| `Static` | The member belongs to the class itself, not individual `objects`. |
| `Constant` | The value **cannot be changed after initialization.** (Checked via `encapsulate/upsert`). |
| `Readonly` | **Prevents writing from outside** the class context (only the class can change it). |
| `Optional` | Allows the property to be `nil` even if a `type` is provided. |
| `Virtual` | Allows the member to be overridden by subclasses. |
| `Reactive` | Wraps the property in an Ignition `Value`, making it observable for UI or state logic. |

!!! tip "Inferred Constants"
    Your properties will automatically be marked as a `Constant` if the provided key is all in **uppercase.**
!!! tip "Readonly can be `nil` on the `.definition` file"
    `Readonly` properties are allowed to be `nil` during the **header definition**, even if they aren't marked as `Optional`. This is because Ignition expects a `Readonly` member to be populated during the class definition` or within the `constructor`.

**Usage Example:**
``` luau
public = {
    -- A property that can be read by anyone but only changed by this class
    Health = property({
        value = 100,
        flags = { FLAGS.Readonly }
    }),

    -- A static constant that belongs to the Class
    MAX_PLAYERS = property({
        value = 10,
        flags = { FLAGS.Static, FLAGS.Constant }
    })
}
```

## Transformers (Accessors)
Sometimes you want a property to look like a simple variable on the outside, but handle complex logic on the inside. Ignition allows you to define `get` and `set` transformers.
* **`get`:** Intercepts the property access and returns a *"presented"* value.
* **`set`:** Intercepts an assignment, transforms the input, and returns what should actually be stored.

!!! info "Constructor Immunity"
    Transformers are ignored during the `constructor`. This allows you to initialize the raw internal value (like a `Stack`, `table`, or other complex structures) before the transformers start *"filtering"* the values for the rest of the game.

**Example: The Virtual Camera Subject**
```luau
public = {
    -- Internally this is a Stack, but externally it looks like a single Instance
    CameraSubject = property({
        value = Stack.new(), -- Internal value
        
        -- The user sees the top of the stack
        get = function(stack)
            return stack:last()
        end,
        
        -- Setting the property actually pushes to the stack
        set = function(newSubject, stack)
            stack:push(newSubject)
            return stack -- Return the internal storage to keep it in the ring
        end
    })
}
```
!!! warning "Type Safety and Transformers"
    If a `set` transformer is provided, Ignition bypasses standard runtime type-checking for that assignment. This allows you to cast values (e.g., passing a `string` that the transformer converts to a `Color3`). You should handle any necessary validation inside your `set` function.

## Static Members via `import`
By providing `FLAGS.Static` to the `flags` field of the `property` helper, a **Static Property** beloning to the class, not object, is made.

Adding to this, the `import` helper also provides access to the `static` side of your class by calling said class and providing `true` (i.e. `MyClass(true)`). This is used when you need to initialize or modify static public properties from within your implementation file.
```luau
local StaticMyClass = MyClass(true)
StaticMyClass.TotalObjectsCreated = 0 -- Writing to a public static field
```
