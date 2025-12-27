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

### What does it offer?
Ignition offers a strictly controlled runtime environment that prioritizes structural integrity and memory safety over *"metatable soup"* (architectural mess, so to say).

* **True Scope Locking (via StackSpider™):** Most libraries use a *"pinky promise"* for private variables, often denoted by prefixing an underscore `_` for intent. Ignition, however, uses **runtime stack reflection** where the class attempts to climb the stack and verify each function ids. When a **function id** is not within any valid context (`Includes`, `Refs`, `Family`, `Friends`, `Constructor`), the class will throw a **hard access violation**.

* **Reactive State Integration:** Properties aren't just plain old values, they can be `State` objects as well. By wrapping your `class` inside a `reactive` decorator, all properties of that class will be created as a `State`; though, if you prefer standalone ones, feel free to do `Value.new()` instead without wrapping your class on a decorator. This allows you to bind class properties directly to UI components (such as **Fusion**) or to other externals systems that automatically update when the property changes.

* **Header-First Workflow:** By separating the **Definition** from the **Implementation**, Ignition creates a clear documentation layer. Any developer can open a `.definition.luau` file and instantly see the class API, properties, and decorators without being distracted by hundreds of lines of logic. It encourages you to design your interface before you write your code.

* **Lazy Linking vs. Eager Requiring:** Ignition registers a `class` interface inside a `Registry`, meaning, it pre-emptively exposes *what* should exists. By utilizing `coroutine.yield()`, Ignition allows classes to reference or extend one another before they are even loaded. While standard `require` trees crash on circular references, Ignition simply waits for the *"handshake"* to complete, allowing for a truly flat and interconnected dependency graph.

* **Encapsulation vs. Types Bandaid:** Some *"Strict Luau"* developers simply omit private members from their type exports to *"hide"* them. This is a band-aid; the data is still there, and any script can still modify it at runtime. Ignition provides **Hard Encapsulation**. If it's not in the Public/Protected contract, it is physically inaccessible to the outside world, regardless of what your type-checker says.

* **Near-Zero Production Overhead:** Ignition is a *Bouncer* in Studio and a *Racer* in Production.
    * **Development:** `StackSpider`™ and other runtime checks are active, enforcing strict access rules and throwing errors on violations.
    * **Production:** By enabling `FORCE_PRODUCTION_MODE`, Ignition strips the proxies and security checks. You get the safety of a high-level language during dev, and the raw speed of Lua in your live game.

### FAQ