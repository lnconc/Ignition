# Inheritance   
Inheritance in Ignition follows a **Single Inheritance** model. A class can inherit from one parent class, gaining access to its `public` and `protected` members.

## Defining Inheritance: `extends`
The `extends` keyword is used in the **header** (`.definition.luau`) file. It establishes a link between the current interface and a super-interface.

```luau
-- Sword.definition.luau
return class "Sword" (extends "Item") {
    public = {
        Damage = 10,
        Swing = function() end
    }
}
```

**Inheritance Rules:**

* **Final Classes:** You cannot extend a class marked with the `final` modifier.
* **Registry Lookup:** You can pass the actual `Interface` object or a `string` (the class name). Ignition will automatically resolve strings via the `Registry`.
* **No Self-Inheritance:** A class **cannot extend itself.**

## Initializing the Parent: `super()`
In your **Implementation** (`.luau`) file, you must call `super()` inside your `constructor` if your class extends another. This triggers the instantiation of the parent object and merges the *"bloodline."*
```luau
-- Sword.luau
local Sword = import()

Sword(function(self, name, damage)
    -- Initialize the 'Item' base class
    super(name) 
    
    self.Damage = damage
end)
```

**How `super()` Works:**

* **Context Capture:** It uses `getCaller` to identify which object is currently being constructed.
* **Parent Instantiation:** it calls the `constructor` of the super-interface with the arguments provided to `super(...)`.
* **`bloodline()` Merging:** It establishes a *"bloodline"* between environments, allowing `protected` access to flow correctly between parent and child methods.
* **Master Reference:** Ignition ensures that both the parent and child share a `Master` object reference, so `self` always points to the most derived object.

## Access Levels in Inheritance
Inheritance respects the three rings of visibility:

| Ring | Accessible by Child? | Description |
| --- | --- | --- |
| `public` | **Yes** | Fully visible to everyone, including child classes. |
| `protected` | **Yes** | Visible to the class and any class that inherits from it. |
| `private` | **No** | Strictly encapsulated. Even children cannot see parent private fields. |

!!! note
    As per usual, parent `objects` cannot see the `private`/`protected` fields of their own children.

!!! danger "Double Initialization"
    You can only call s`uper()` once. If you attempt to call it multiple times, or if the class already has an initialized super-object, Ignition will throw an `ALREADY_INHERITS` error.