# Class Functions
Now that we've learned how to import a class definition and set up a constructor, we'll move on to how to implement functions.

In Ignition, **Class Functions** (often called methods) define the behavior of your class. Unlike standard Luau functions, Ignition functions are wrapped in a `func {}` constructor within your `.definition` file. This allows the framework to enforce **Access Specifiers**, **Exposure** (Network boundaries), and provide **Type Autocomplete** via the dummy field.

## Defining the Contract
Before a function can be used, it must be declared in the header. The `func` helper is used to define the *"rules"* for that function.
``` luau
-- BaseRemote.definition.luau
protected = {
    Send = func {
        from = "shared",
        dummy = (nil :: any) :: (self: any, data: any) -> ()
    }
}
```

### The `func` Constructor
The `func` helper accepts an options table:

* **`exposure`:** Defines if the function exists on the `"client"`, `"server"`, or `"shared"`. If the network environment doesn't match, the function is never even defined.
* **`flags`:** Optional modifiers like `FLAGS.Static` or `FLAGS.Virtual`.
* **`dummy`:** A *"ghost"* function used strictly for Luau's type engine. This ensures that when you type `self:Send(`, you get perfect autocomplete.

## Implementing the Logic
Once the contract is imported into your source file, you implement the logic by assigning it to the `ImportedClassObject`.
!!! info "Write-Only Implementation"
    As earlier stated from [Class Importation](./Class Importation.md), the `ImportedClassObect` returned by `import()` is write-only. You can assign functions to it, but you cannot read from it.

``` luau
-- BaseRemote.luau
local BaseRemote = import(BaseRemoteHeader)

-- The implementation
function BaseRemote:Send(data: any)
    print(`Sending data: {data}`)
end
```

### Behind the Scenes: The Wrapper
When an object is initialized, Ignition doesn't just give the object your raw function. It creates a `wrapper`. This `wrapper` performs a critical security check:

It verifies that the function is being called with the `:` syntax (colon). If you try to call a non-static method with `.`, the `wrapper` will throw an Invalid Call Signature error to prevent `self` corruption.

## Static Functions
By providing the `FLAGS.static` to the `flags` field of the `func` helper, a **Static Function** belonging to the class, not the object, is made. They do not have a `self` variable and can be called without creating an object first.

### Behind the Scenes: Function Wrapping
When you define a function in your implementation file, Ignition doesn't just put it in a table. The `initialize` function sequences:

1. **Extracts** the closure from your implementation.

2. **Wraps** it in a security layer that validates `self`.

3. **Injects** the framework environment so the function can access `protected` or `private` data safely.

3. **Registers** the closure within the object's environemnt security context.

!!! tip "Function Overloading"
    Ignition supports complex method overloading (defining multiple versions of a function with different parameters). Because this is an advanced architectural pattern, it is covered in the [Advanced: Overloading](../advanced/Function Overloading.md) section.