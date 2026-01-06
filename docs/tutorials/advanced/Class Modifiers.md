# Class Modifiers
Class Modifiers are high-level transformations applied to the class definition`. They change how the class can be inherited, instantiated, or how it handles data internally.

You apply them by wrapping the class declaration in your header file:
```luau
-- Example of multiple modifiers
return final(reactive(class("InternalState") {
    public = {
        Value = 0
    }
}))
```

## The `abstract` Modifier
The `abstract` modifier marks a class as a *"blueprint only."* It prevents the class from being instantiated directly via `new`.
To use an `abstract class`, it must be extended by another class.

An example of using the `abstract` modifier is by creating the base class **Shape** that provides logic for **Area**, but should never exist as a standalone *"Shape"* object.

## The `final` Modifier
The `final` modifier is the opposite of `abstract`. It marks the **end** of an inheritance chain. This modifier prevents any other class from extending this class.
If a class tries to `extends` a finalized class, Ignition will throw a `FINAL_CLASS_EXTEND` error.

An example of using this modifier are core utility classes where you want to guarantee that logic hasn't been tampered with or overridden.

## The `reactive` Modifier
The `reactive` modifier is an Ignition-specific transformation that turns the class into a state-driven machine. It automatically wraps every property in the class (`public`, `private`, and `protected`) into a `Value` object.

When this is applied:
* Every field becomes a *"State"* that can be observed. 
* When you index a property, it returns the `Value` object.
* When you set a property, it triggers dependency updates.

An example of using the `reactive` modifier are *"Data Stores"* or *"State Containers"* where every single change needs to sync to UI or other systems without manually marking every field as `PROPERTY_FLAGS.Reactive`.

## Modifiers vs. Property Flags
It is important to distinguish between Class Modifiers and Property Flags.

| Feature | Class Modifiers | Property Flags |
| --- | --- | --- |
| **Scope** | Applies to the entire Class. | Applies to a single member. |
| **Syntax** | `modifier(class("Name") { ... })` | `{ Value = property { value = 0, flags = { FLAGS.Static }} }` |
| **Example** | `abstract`, `final`, `reactive` | `Readonly`, `Constant`, `Static` |

!!! info "Modifier Stacking"
    Modifiers can be stacked. For example, a `reactive(final(class("X")))` is a class that cannot be inherited from and has entirely reactive properties. Order *generally* does not matter, as they each flip a specific bit in the interface.flags table.

    Just know that attempting to finalize an `abstract class` or vice versa **will** throw an error.