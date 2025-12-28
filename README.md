<h1 align="center"><b>Ignition</b></h1>
<p align="center"><em>A True OOP & Reactive State DI Framework</em></p>
<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-orange.svg" />
  <img src="https://img.shields.io/badge/Roblox-Open%20Source-blue.svg" />
</p>

## 🚀 Quick Start
Ignition utilizes a **Functional DSL** to define class interfaces and a **Decoupled Linker** for implementations. This structure eliminates circular dependencies and enforces strict memory safety.

### 1. The Header (`MyClass.definition.luau`)
```lua
local Class = require(game.ReplicatedStorage.Ignition).Class
local class, property, once, final = Class.from("class", "property", "once", "final")
if once() then return false end -- #pragma once

final (class "MyClass" { 
    public = {
        Health = property { type = "number", value = 100 },
        Hello = "World!"
    },
    private = {
        Secret = "Encapsulated!"
    }
})

return true
```
### 2. The Source (`MyClass.implementation.luau`)
```lua
local Class = require(game.ReplicatedStorage.Ignition).Class
local import = Class.from("import")

local MyClass = import() -- Implementation is write-only

-- The constructor
MyClass(function(self) 
    print(`{tostring(self)} initialized.`)
    -- Encapsulation (via StackSpider) prevents outside scripts from seeing this:
    print(self.Secret) 
end)

return true
```
### 3. Usage (`main.server.luau`)
```lua
local new = require(game.ReplicatedStorage.Ignition).new
-- Ignition loads everything in folders with the word "Solution" upon requiring.

local instance = new "MyClass"()
print(instance.Hello)  -- "World!"
instance.Health = 50
print(instance.Secret) -- ERROR (attempt to access private member)
```

## 🧠 Why Ignition?
Most OOP libraries are **monolithic:** both definition and implementation living at the same table, making circular dependencies a *constant threat and eventual hassle* on large-scale projects (calling out poor file structure organizers like me). Ignition introduces a **Decoupled Lifecycle** inspired by C++ environments.

### ✔️ What does it offer?
Ignition offers a strictly controlled runtime environment that prioritizes structural integrity and memory safety over *"metatable soup"* (architectural mess, so to say).

* **True Scope Locking (via StackSpider™):** Most libraries use a *"pinky promise"* for private variables, often denoted by prefixing an underscore `_` for intent. Ignition, however, uses **runtime stack reflection** where the class attempts to climb the stack and verify each function ids. When a **function id** is not within any valid context (`Includes`, `Refs`, `Family`, `Friends`, `Constructor`), the class will throw a **hard access violation**.

* **Reactive State Integration:** Properties aren't just plain old values, they can be `State` objects as well. By wrapping your `class` inside a `reactive` decorator, all properties of that class will be created as a `State`; though, if you prefer standalone ones, feel free to do `Value.new()` instead without wrapping your class on a decorator. This allows you to bind class properties directly to UI components (such as **Fusion**) or to other externals systems that automatically update when the property changes.

* **Header-First Workflow:** By separating the **Definition** from the **Implementation**, Ignition creates a clear documentation layer. Any developer can open a `.definition.luau` file and instantly see the class API, properties, and decorators without being distracted by hundreds of lines of logic. It encourages you to design your interface before you write your code.

* **Lazy Linking vs. Eager Requiring:** Ignition registers a `class` interface inside a `Registry`, meaning, it pre-emptively exposes *what* should exists. By utilizing `coroutine.yield()`, Ignition allows classes to reference or extend one another before they are even loaded. While standard `require` trees crash on circular references, Ignition simply waits for the *"handshake"* to complete, allowing for a truly flat and interconnected dependency graph.

* **Encapsulation vs. Types Bandaid:** Many developers use *"Types as a Bandaid,"* they just omit `_secret` properties from their exported types so they don't show up in Autocomplete. This is a promise, not a lock.
    * **The Bandaid:** The property is still there; any script can accidentally (or maliciously) change `object._secret`.
    * **The Ignition Lock:** By using Hard Encapsulation, the data is physically walled off. If a script tries to access a private member, Ignition's `encapsulate.luau` detects the unauthorized call and stops it. It doesn't matter what your Luau types say; the runtime is the one enforcing the law.

* **Near-Zero Production Overhead:** Ignition is a *Bouncer* in Studio and a *Racer* in Production.
    * **Development:** `StackSpider`™ and other runtime checks are active, enforcing strict access rules and throwing errors on violations.
    * **Production:** By enabling `FORCE_PRODUCTION_MODE`, Ignition strips the proxies and security checks. You get the safety of a high-level language during dev, and the raw speed of Lua in your live game.

* **Composition via Mixins:** Ignition allows for true horizontal composition. You can inject the properties and methods of multiple *"Component"* classes into a single class without creating a messy inheritance chain.

    * **Collision Protection:** Ignition automatically detects if two mixins are trying to overwrite the same member. If they aren't marked as virtual, Ignition throws an error during the linking phase, preventing silent logic bugs.

* **Explicit Inheritance & Virtuals:** Most Roblox OOP systems allow you to override anything, anytime, which is dangerous for large teams. Ignition introduces **Virtual Overrides**:

    * You cannot override a property or method unless the parent explicitly marked it with the `FLAGS.Virtual` flag.
    * This prevents *"Accidental Shadowing,"* where a child class unknowingly breaks a base-class internal function.

### ❓ FAQ
1. ***"Is this just more 'Metatable Soup'?"*** No. In traditional OOP, you manage the metatables yourself, leading to an architectural mess. In Ignition, the metatables are internal engine components. You write clean, declarative code; Ignition handles the "soup" behind the scenes so you don't have to.

2. ***"Why the two-file system?"*** It's about **scale**. Standard one-file classes crash when they reference each other (Circular Dependencies). Ignition's split system allows the Registry to map out your game before the logic ever runs, making it impossible to "break" your requirements.

### 💡 Tips & Best Practices
1. **Mastering Member Modifiers:** Ignition supports C++ style modifiers to give you absolute control over your class members.
    * `FLAGS.Static`: Marks a member as belonging to the `Class`, not the `Instance`.
        * **Static Properties:** Shared across all instances.
        * **Static Functions:** These are stripped of the self variable. Use them for utility functions that don't need instance data.
    * `FLAGS.Virtual`: Required if you intend for a member to be voverridden in a subclass**. If a child class tries to overwrite a non-virtual member, Ignition will throw an error to prevent accidental logic breakage.
    * `FLAGS.Constant`: Once initialized in the constructor, the value is **locked forever**.
    * `FLAGS.Optional`: Marks the property as **nullable**, preventing *"attempt to index missing property"* errors during runtime.
    * `FLAGS.Readonly`: Prevents any modification to the property after initialization (or more concisely, it only permits modification **inside** the `constructor`). Perfect for IDs or `Configuration` constants.

2. **Static Methods vs. Instance Methods:** If you define a function in your header as static, Ignition treats it as a Pure Function.
    * **Instance Method:** Automatically receives self as the first argument.
    * **Static Function:** Stripped of self. Perfect for utility functions or factory methods that don't need to touch instance data.

3. **The `ref()` Rule for Callbacks:** When passing an anonymous or external function to an external system (like `RunService.Heartbeat:Connect` or `task.spawn`), always wrap it in `ref()`.
    * **Why?** Luau's engine signals run on a separate stack. Without `ref()`, the **StackSpider**™ won't recognize the caller and will throw an access violation.
    * `ref(self.MyMethod)` creates a secure tunnel for that specific function, allowing it to use that specific `class`'s `private` and `protected` fields.
    ```lua
    local ref = Class.from("ref")

    MyClass(function(self)
        task.spawn(function()
            print(self.Secret) -- ERRORS! (attempt to index private property "Secret")
        end)
        task.spawn(ref(function()
            print(self.Secret) -- SUCCESS! (prints Secret)
        end))
    end)
    ```
> [!IMPORTANT]
> `ref()` can only be called inside the methods or constructors of a class. Calling it outside will throw an error.


4. **Overriding with `FLAGS.Virtual`**: Ignition enforces strict inheritance. You cannot override a property or method in a child class unless it was marked as a virtual in the parent. This prevents *"Accidental Shadowing"* where a subclass unknowingly breaks a parent's core logic.

5. **Managing the Engine**
    * **The Configuration Module:** Found under `Class/Utility`, this is your control center. You can adjust `MAX_STACK_DEPTH` (for StackSpider tuning), `FLAGS`, special signatures, and even on how your `definition` files should be named (by default, it expects a `.definition`).

    * **Testing Performance:** By default, Ignition knows if you are in Studio and enables *"Bouncer"* mode. To test your game's raw speed while still in Studio, toggle `FORCE_PRODUCTION_MODE` in the config to switch to *"Racer"* mode.

6. **Constructors:** The returned object from `import()` has a `__call` method, this callback serves as your primary way of creating constructors as it provides the necessary wrapping and measures internally required by `Class`.
    ```lua
    local import = Class.from("import")
    local MyClass = import() -- returns a write-only implementation with a __call method
    MyClass(function(self)
        print(`{tostring(self)} created.`)
    end)
    ```

### 📂 Project Structure & Naming
To ensure the **Solution Linker** (upon using `require(path.to.Ignition)`) and `import()` function work correctly, follow this standardized layout. Ignition's auto-loader specifically looks for the **"Solutions"** keyword.
```
Root
 └── ExampleSolution <-- Without the keyword, this gets ignored
      └── Player
      |   ├── Player.definition.luau     <-- The "Header" (similar to Player.h)
      |   └── Player.implementation.luau <-- The "Source" (similar to Player.cpp)
      └── main.server.lua
```

> [!WARNING]
> `import()` is strictly case-sensitive. It extracts the class name from the file name. If your file is `Zombie.implementation.luau`, it will search the `Registry` for the interface `Zombie` by omitting `.implementation.lua` from the name.

> [!IMPORTANT]
> `Registry` innately prevents its own functions from being called by external scripts via `assertCallingScript()`, and only scripts inside the `Class` folder structure can. Doing so will throw an **error**.

### 🛠️ Memory Management
Use the `free()` primitive for deep cleanup. Instead of just setting variables to `nil`, `free(item)` will:
1. Call `:Destroy()` if it's an `Instance`;
2. Call `:Disconnect()` if it's a `Connection`;
3. **Recursively clear** tables and their keys; or,
4. Call the function if you pass a closure (acting as a destructor).
```lua
local free = Class.from("free")

MyClass(function(self)
    self:OnDestroy(function()
        free(self.ActiveTweens) -- Cleans the table and all its contents
    end)
end)
```

> [!NOTE]
> `State` objects provides a `:Destroy`, so feel free to use `free()` on this. Additionally, `Class` automatically passes a destructor (being `free` itself) when reactivity is allowed.

> [!WARNING]
> `State` objects throws a warning when an instance of metatable is passed without a destructor.

## 🛠️ Additional OOP Features