# **Getting Started**
Welcome to Ignition's tutorial section! Here, you'll learn how to architect code strictly and intuitively with Ignition.

!!! failure "But wait, heed before you proceed..."
    **Ignition is not your friend; it is your supervisor.**

    If you are looking for a *"plug-and-play"* utility library to sprinkle into an existing project, **turn back now.** Ignition is a strict architectural framework that physically enforces the boundaries of your code.  

    By proceeding, you must be aware that:

    * **The Spider is Watching:** The `StackSpider` will crash your thread if you attempt to *"cheat"* your way into private members from the wrong scope.

    * **Header-First or Fail:** You cannot *"duct-tape"* logic together. You must define your interface in a `.definition` file before you are allowed to write a single line of implementation.

    * **No "Metatable Soup":** Ignition kills the *"pinky-promise"* style of OOP. There are **<u>no</u>** underscores here; there are only hard access violations and strict type-matching.

    * **The `ref()` Tax.. and others..:** You must manually wrap callbacks in `ref()` when crossing engine boundaries, or the security system will treat your own code as an intruder.

    This rigidity is a feature, not a bug.
    Ignition is designed for large-scale, high-integrity systems where "moving fast and breaking things" is replaced by **"designing once and running forever."**

    If you aren't 100% willing to let a framework dictate your file structure and access patterns for the sake of absolute memory safety and zero-overhead production speed, Ignition is not for you.

---

## **What You Need To Know**
These tutorials assume:

* You are comfortable with Roblox and the Luau scripting language.
    * By extension, you are familiar with C++ or Java coding paradigms.
* You have basic understanding on the concepts of Object Oriented Programming.
* You are ready with choosing between eager or lazy linking.
    * You are comfortable with losing intellisense when you use lazy linking
* You are comfortable with wrapping engine level callbacks in `ref()`. (1)
    { .annotate }

    1. You must use `ref()` whenever a function is called from a non-scripting thread (like `RunService` or `task.delay`) to prevent `StackSpider` access violations.

Of course, depending on your background, some concepts may feel more alien than others. Ignition is built for professional endurance; the initial friction you feel is simply the framework ensuring your architecture is bulletproof, so don't be discouraged.

## **Installation**

You can deploy Ignition into your project using one of the following strategies.

### **Wally (Recommended)**
Wally is the standard package manager for professional Luau development.

1. Copy `Ignition = "lnconcinnity/ignition@latest"` for the latest release.
2. Paste the string under the `[dependencies]` section of your `wally.toml`.
3. Run `wally install` in your command line.

### **Source Code**
Use this method if you synchronize external files into Roblox Studio via Rojo.

1. Download the source code ZIP from the [latest release](https://github.com/lnconc/Ignition/releases/latest).
2. Copy the `src` folder from the ZIP archive.
3. Paste the folder into your project's `shared` or `lib` directory.
4. Rename the folder to `Ignition`.

### **Roblox Model (.rbxm)**
This is the fastest method for developers working exclusively inside Roblox Studio.

1. Download the `Ignition.rbxm` file from the [latest release](https://github.com/lnconc/Ignition/releases/latest).
2. Drag and drop the file directly into the Roblox Studio Explorer.
3. Place the folder into `ReplicatedStorage` for shared access.

### **Creator Store (Toolbox)**
You can add Ignition to your inventory through the Roblox Creator Store.

1. Open the **Toolbox** in Roblox Studio.
2. Search for `Ignition`, with **lnconcinnity** filtered as creator, under the Models tab.
3. Click the model to insert it into your current place.

## Quick Start
Ignition is a **Dependency Injection (DI)** framework. Your primary concern is no longer *"where the script goes,"* but how you structure your `Solutions`.
### 1. Project Structure
Ignition crawls your environment to find folders suffixed with Solution. It then automatically links every module inside them.
```
Root (ServerScriptService / StarterPlayerScripts)
 └── GameSolution
     └── Player
         ├── Player.definition     <-- The "Interface" (Header)
         └── Player                <-- The "Logic" (Source)
```

### 2. Creating a `class`
Ignition enforces a strict separation between *what* a class **is** and *what* a class **does.**

=== "BaseRemote.definition"
    This is an example of a `.definition` file and how it's structured, this is your **contract.** It defines public and protected members.

    ``` luau
    --!strict
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Ignition = require(ReplicatedStorage.Ignition)

    local class, property, abstract, func, FLAGS = 
        Ignition.class, Ignition.property, Ignition.abstract, Ignition.func, Ignition.FLAGS

    return abstract (class "BaseRemote" {
        public = {
            Name = property {
                exposure = "shared",
                flags = { FLAGS.Readonly },
                type = "string",
                value = nil
            },
        },
        protected = {
            Send = func {
                exposure = "shared",
                dummy = (nil :: any) :: (self: any, options: {
                    targets: { Player },
                    unreliable: boolean,
                    args: { [number]: any, n: number },
                }) -> (),
            },
        },
    })
    ```

=== "BaseRemote"
    The implementation file is your **source.** You use `import()` to bind your logic to the definition.

    ``` luau
    --!strict
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Ignition = require(ReplicatedStorage.Ignition)

    local import = Ignition.import
    local BaseRemoteHeader = require(script.Parent["BaseRemote.definition"])

    local BaseRemote = import(BaseRemoteHeader)
    type BaseRemoteInstance = typeof(BaseRemote)

    function BaseRemote:Send(options)
        -- Logic for sending data
    end

    -- The Constructor
    BaseRemote(function(self: BaseRemoteInstance, name: string)
        self.Name = name
    end)

    return BaseRemote:__complete__() -- mark it as complete
    ```

    !!! danger "Type Integrity Warning"
        This example **eagerly loads** the interface by directly requiring the header (which allows the type solver to properly infer the `class` object thanks to traceability). While Ignition allows **lazy loading** by leaving `import()` empty, doing so causes you to <u>lose</u> **ALL** type    inferences (`Types` will return `any` instead). 
        
        **Design your architecture accordingly.**
!!! tip
    Skip the hassle of having to manually define either both of your *header/source* files by using these [QoL snippets for VSCode](https://raw.githubusercontent.com/lnconc/Ignition/refs/heads/master/.vscode/ignition.code-snippets)!
    
    Do note that the snippet for **implementation/source files** are on **EAGER**, which risks circular dependencies, *but who in their right mind would circularly reference the header and source files?*

### 3. System Configuration *(Optional)*
Before the system is live, you can modify the `Configuration` file within the Ignition core. This defines where the framework looks for code and what it ignores.
``` luau
-- Ignition/Configuration
return {
    VERSION = version,
    -- Defines where Ignition starts crawling for Solutions
    ROOT = if game:GetService("RunService"):IsServer() 
        then game:GetService("ServerScriptService") 
        else game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"),
    
    SHARED_ROOT = game:GetService("ReplicatedStorage"),
    
    -- Names that Ignition will never crawl
    EXCLUDES = set("assets", "templates", "prefabs", "temp"),
    
    -- The suffix required for a folder to be treated as a Solution
    SOLUTIONS_KEY = "Solution",
}
```
!!! tip
    Modifying the `ROOT` allows you to restrict Ignition to specific sub-folders, reducing the crawling overhead in massive projects.

### 4. Igniting the Engine
The final step is the initialization. This is done by `require`-ing the Ignition module and calling it as a function.

#### Override Definition Extensions
By default, Ignition looks for `.definition` files. However, you can pass a string argument during initialization to override the expected file extension (e.g., if you prefer `.interface` or `.header`, or more efficiently: `.d`).
``` luau
-- main.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Initialize with an optional extension override
-- 2. This begins the Linker sequence across ROOTS and SHARED_ROOT
local Ignition = require(ReplicatedStorage.Ignition)(".d") 

-- And that's it!
local new = Ignition.new

local baseRemote = new "BaseRemote"("Message")
print(baseRemote.Name) -- Message
baseRemote.Name = "SendMessage" -- ERRORS (Since it's a readonly property, you cannot set it once outside the constructor!)
```

If no errors were raised, the system is now operational. Any class defined in your solutions is now globally accessible and architecturally enforced.

## Troubleshooting

!!! question "Why can't I instantiate a class with new?"
    The most common reason for this is that your *header/source* files were not indexed by Ignition. Verify that:

    * Your files are placed inside a folder with the `Solution` keyword at the end (e.g., `GameSolution`).
    * Your files are **not** located within folders defined in `Configuration.EXCLUDES`.
    * You have called the Ignition module as a function `require(Ignition)()` to start the crawl.

### Common Pitfalls
1. **Incorrect Extension Overrides**

    If you passed an override to the Ignition constructor (e.g., `require(Ignition)(".d")`), but your files are named `.definition`, Ignition will ignore them. **Ensure your file extensions match your configuration exactly.**

2. **Implementation Errors vs. Definition Validity**
    Because Ignition separates the two, an error in your **implementation** file (syntax error, logic crash) will not prevent the **definition** from being registered.

    * The Result: You can still call `new(targetClass)(...)` on the class, but the logic will fail or appear *"empty"* because the implementation **never successfully bound itself to the header** via `import()`.

3. **Lazy Loading Deadlocks**
    Ignition supports *lazy loading* by passing a string to `new` instead of the actual `Interface` object. While flexible, this can lead to silent failures:

    * If the class name is misspelled or the file hasn't been crawled yet, the `Registry` will yield the thread while it waits for that class to exist.
        * *Though on later versions of Ignition now has `Registry` with an internal timeout handler, it is best advised to look into your code structure as this may very well be a code smell.*

### Under the Hood: The `Registry`
The `Registry` is the source of truth for all active interfaces. It uses `coroutine.yield()` to manage dependencies, ensuring that one class doesn't attempt to inherit from or link to another class that isn't ready.

The `Registry` also handles the cold-loading deep inheritance chains (e.g., `Child` propagates upward to `Grandparent` first, then descends back from `Grandparent` to `Child`).

!!! warning
    The `Registry` strictly forbids calls from scripts outside the Class scope to prevent developers from *"manually"* injecting fake classes into the framework. Thus, the `Registry` is architecturally a blackbox.