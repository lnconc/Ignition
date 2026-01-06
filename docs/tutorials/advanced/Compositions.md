# Compositions

Composition is the process of combining multiple small, focused interfaces into a single, complex class. Unlike inheritance, which passes down a *"bloondline,"* a `mixin` performs a **Field-Level Copy**. It harvests the properties and closures from existing classes and grafts them onto a new one.

## Defining a Mixin: `mixin`
The `mixin` keyword is used in the **header** (`.definition.luau`) file. It takes the name of your new class, followed by a list of existing classes (`components`) you want to include.

``` luau
-- Character.d.luau
local mixin = Ignition.mixin

return mixin "Character" ("HealthComponent", "InventoryComponent") {
    public = {
        Name = "Player",
        WalkSpeed = 16
    }
}
```

**How it Works:**

1. **Grafting:** Ignition looks up the `"HealthComponent"` and `"InventoryComponent"` in the `Registry`.
2. **Property Injection:** It copies every property (`public`, `private`, `protected`) from the `components` into the new `Character` class.
3. **Closure Adoption:** It copies the methods (closures) from the `components`.
4. **Collision Protection:** If two `components` have the same property name, Ignition throws a `MIXIN_COLLISION` error, unless the properties are flagged with `FLAGS.Virtual`.
    * If collisions occur, Ignition follows a **Last-Write Prioritization.**

## Collision Handling & Virtuals

Because `mixins` merge multiple sources into one, naming conflicts are a risk. Ignition uses strict rules to ensure your class logic remains predictable:

### Last-Write Prioritization
Ignition processes components from **left to right.** If `ComponentA` and `ComponentB` both define `Strength`, and both are non-virtual, the engine will throw a `MIXIN_COLLISION`.

However, your **Main Class Definition** (the table at the end of the `mixin` call) always has the final word. It acts as the ultimate override for any properties provided by the components.

### Virtual Overrides
If a component property is marked with the `FLAGS.Virtual` flag, it signifies that the property is intended to be replaced.

* **Strict Blocking:** You cannot mix two components that share the same **non-virtual** key.
* **Virtual Override:** If the keys are virtual, the later component (or the main class) will overwrite the previous one without throwing an error.

```luau
-- DamageComponent.d.luau
public = {
    BaseDamage = property {
        value = 10,
        type = "number" :: "number"
        flags = { FLAGS.Virtual }
    }
}

-- Boss.d.luau
return mixin "Boss" ("DamageComponent") {
    public = {
        -- This safely overwrites the Virtual property from DamageComponent
        BaseDamage = 100
    }
}
```

## Feature,Inheritance (extends),Composition (mixin)
| Feature | Inheritance (`extends`) | Composition (`mixin`) |
| --- | --- | --- |
| **Relationship** | Vertical (Parent/Child) | Horizontal (Assembly/Parts) |
| **Structure** | Single Parent only. | Multiple Components allowed. |
| **Memory** | Creates a `SuperClass` object. | Flattens all properties into one object. |
| **Visibility** | Respects `protected`. | Copies everything (including `private`). |
| **Methods** | Uses `super()` to initialize. | Automatic (Implementation shared). |

!!! warning "Important Constraints"
    You cannot use a class marked as `final` as a component in a `mixin`. This throws a `MIXIN_FINALIZED` error.
    Because `mixins` perform a field-copy, the composite class gains access to the `private` and `protected` fields of its components. **Use this power wisely to avoid spaghetti dependencies**.