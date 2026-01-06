# Optimizations
Ignition is engineered to be as light as possible while still offering robust safety features. However, running a full security suite and reactivity engine in a production environment can be overkill. This is why Ignition features a dual-mode system that adapts to your workflow.

## Production vs. Development Mode
Ignition recognizes that the checks you need while writing code are different from the ones you need when players are in your game.

* **Development Mode:** This is the default state. Ignition runs the full `StackSpider` to monitor visibility, performs strict type-checking on every property assignment, and provides verbose warnings if it detects potential memory leaks.
* **Production Mode:** When you enable `FORCE_PRODUCTION_MODE` or play via the Roblox Player, Ignition strips away the expensive safety nets. It swaps the complex visibility rings for optimized hash-map lookups and bypasses non-critical type assessments to ensure your classes run with near-native Luau performance.

## The `StackSpider` Cache
The `StackSpider` is the heart of Ignition's `encapsulation` system, but walking the call stack to verify security is an expensive operation. To solve this, Ignition uses a high-performance caching strategy:

* **Memoization:** Once the spider determines a caller's access level for a specific object, it memoizes that result using a weak-keyed `accessCache`.
* **Resolution Tracking:** It tracks which functions are *"included"* or *"protected"* within a class's family tree, allowing it to skip future stack traversals for that specific closure.
* **Context Recycling:** Ignition caches the resolution of call sites, meaning it only has to identify the *"true"* caller once per unique script context.

## Proxy Performance
When you interact with an Ignition object, you are actually talking to a Thin Proxy created via `newproxy`.

In **Production Mode**, this proxy is *significantly faster*. Instead of checking multiple visibility rings (`public`, `private`, `protected`), it maps **directly to a flattened data table.** This means that once your class logic is finalized, property access becomes a simple table index operation, almost entirely removing the overhead of the encapsulation logic.

## Lightweight Primitives
Many of Ignition's internal tools are designed to be *"zero-cost"* in production. For example, utilities like `ref()` and `anon()` provide vital context-tracking during development to ensure `encapsulate` and the `StackSpider` work correctly. In Production Mode, these functions become simple identity passes that returns your original callback immediately without any wrapping or overhead.

## Reactive Fast-Paths
The reactivity engine doesn't just evaluate state; it optimizes it. The `initialize` and `upsert` logic includes *"dirty-checking"* to prevent unnecessary updates. If a value hasn't changed, Ignition won't trigger the dependency graph, saving precious CPU cycles during high-frequency state changes.

## Garbage Collection & Memory Safety
In a perfect world, you would just set an object to `nil` and forget it exists. While Ignition uses weak tables extensively to avoid holding onto objects you've stopped using, the complexity of a *"protected"* environment creates unique challenges.

### The Challenge of Automatic Cleanup
Ignition relies on **Context Tracking**. To make features like `super()` and `private` visibility work, the engine needs to know which function is currently running and which class *"owns"* that function.

As you can see in `StackSpider` and `anon`, we store these relationships in lookup tables.

* **The Key Problem:** If we use strings (like the traceback or method names) as keys, those strings are *"strong."* They will never be garbage collected as long as the table exists.
* **The Function Problem:** If we switch to using the `function` objects themselves as keys in a weak table, the GC could *theoretically* clean them up. However, in Luau, a method often holds a reference to the `self` (the object), and the object (via its `environment`) holds a reference to its methods. This creates a Reference Cycle.

### Why `delete()` is Mandatory
Because of these cycles, Ignition requires an explicit *"kill singal".* When you call `delete(object)`, the engine performs a surgical strike on these references:

#### 1. The Bloodline Severance
As seen in `delete`, the engine doesn't just `nil` out the object. It iterates through the `environment.Closures` and explicitly calls `StackSpider.delete(closure)`. This wipes the cached security data for every method associated with that instance, breaking the cycle immediately.

#### 2. Recursive Destruction
Ignition objects are often layered. If your `Warrior` class extends `Human`, calling `delete(warrior)` will automatically travel up the tree and delete the Human super-object as well. This ensures that hidden internal state isn't left "floating" in memory.

#### 3. The free() Logic
The `free() `utility is the final stage of the process, recursively `free`ing members of the encapsulated `data` table.

By using `delete()`, you aren't just letting the GC *"eventually"* find the object; you are forcing a deterministic cleanup of every signal and instance the object touched.

### Memory Auditing
For developers who want to verify their cleanup logic, Ignition provides a specialized auditing tool.

#### Global & Local Health
The `dumpsize()` utility allows you to peek under the hood of the engine's internal caches. It can be used in two ways:

1. **Global Engine Health:** Call it without arguments to see the size of the global `StackSpider` caches and the total number of registered environments.
2. **Object Context Audit:** Pass a specific object to see its internal Context. This reveals the count of internal methods (`includes`), external references connected via `ref()` (`refs`), and the size of its inheritance family tree.

```luau
local dumpsize = from "Ignition" ("dumpsize")

-- Global audit
print(dumpsize()) 
--> stackspider (access): 142, env: 12

-- Specific object audit (Development Mode only)
local warrior = Warrior.new()
print(dumpsize(warrior))
--> context (includes): 12, context (refs): 2, family: 45, closures: 12
```

!!! info "Context Availability"
    Object context auditing is only available in Development Mode. In Production Mode, the `Context` table is stripped from the environment to minimize memory footprint.