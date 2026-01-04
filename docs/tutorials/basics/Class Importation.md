# Class Importation

Ignition uses a **Dual-File System**. Before you can write the logic for a class, you must *"bind"* your source file to its definition. This is done using the `import` function.

Importing serves two critical purposes:

1. It ensures the implementation matches the contract defined in the header.
2. It provides the Luau type solver with the information needed for autocompletion and type inference, as well as access enforcement according to style rules.

``` luau
--!strict
-- BaseRemote.luau (The Source)
local Class = require(ReplicatedStorage.Ignition).Class
local import = Class.import
local BaseRemoteHeader = require(script.Parent["BaseRemote.definition"])

-- The Importation
local BaseRemote = import(BaseRemoteHeader)
```

## The `import` Mechanism
When you call `import()`, Ignition returns a **write-only** `ImportedClassObject` prototype, with said prototype, it internally runs checks and other needed operations *such as virtuals and overloading*.

This prototype is what you will use to define your constructor and methods.
!!! danger "Eager vs. Lazy Loading"
    As mentioned in the Quick Start, you can leave `import()` empty to lazily load the interface by name.
    **However**, this is discouraged for standard classes as it breaks static type checking. Always prefer passing the `definition` directly.

## The Constructor and Destructor
The constructor is the initialization sequence of your object. Unlike other frameworks that use a named method (like `init` or `new`), Ignition treats the `ImportedClassObject` itself as a function.

=== "The Constructor"
    To define a constructor, you call the imported class and pass a callback. This callback is executed every time the `new` function is called to instantiate a `class`.
    ``` luau
    -- The Constructor
    BaseRemote(function(self: BaseRemoteInstance, name: string)
        self.Name = name
        print(`Constructed {self.Name}`)
    end)
    ```
    **Parameters:**

    1. `self:` The first argument is always the instance being created.
    2. `...:` Any arguments passed to `new (targetClass) (...)` are forwarded here.

=== "The Destructor: `delete()`"
    In Ignition, `:Destroy()` is considered a side effect. While it may handle the cleanup of physical instances, it does not guarantee the destruction of the Ignition object's internal state or its presence in the Registry or other internals.

    To properly decommission an object, you must use the `delete()` function.

    ``` luau
    local Class = Ignition.Class
    local delete = Class.delete

    local remote = Class.new("BaseRemote")("MyRemote")

    -- Proper disposal
    delete(remote)
    -- Purges the object, data, closures, references; everything
    -- Calling this also poisons its metamethods, mainly __index and __newindex to
    -- truly decommission the object
    ```

    **What `delete()` actually does:**

    1. **Recursive Cleanup:** It travels up the inheritance chain, calling `delete()` on all `superclass` objects.
    2. **State Purging:** It iterates through the object's data rings and calls `free()` on every member. (1)
        { .annotate }

        1. `free()`, much like as `delete()`, is another memory helper function that works similarly as **Maids and Janitors**. It properly disposes of `Instances`, `Connections`, and `tables`, and also invokes clean-up `functions`.

    3. **Metatable Mutilation and Poisoning:** It replaces all metamethods (like `__index`, `__add`, etc.) with a stub that throws an error if the object is accessed again.
    4. **Closure Erasure:** It wipes all closures associated with the object from registries, namely `env`, `anon`, and `StackSpider`
    
    !!! danger "Zombie Objects"
        Because `delete()` replaces metamethods with errors, any code holding a reference to a deleted object will crash immediately upon trying to use it.
        
        **This is intentional, it forces you to handle object lifetimes cleanly.**