# Memory & Context Management
In a scoped OOP system, the hardest challenge is maintaining *"Context."* When you pass a function to the Roblox engine, it loses its connection to your object. Ignition solves this with **Context Helpers**, while ensuring the internal destructors and purgers cleans up everything afterward.

## The Design Philosophy of Context Helpers
Ignition provides two specific ways to wrap anonymous functions. Choosing the right one depends on whether the function is a **logical part** of the class or a **temporary bridge** to the engine.

### The Logical Identity: `anon`
`anon` uses **Idempotency.** It hashes the script path and line number (traceback) of where it was created. If your code runs `anon(function() ... end)` 100 times in a loop at the same line, Ignition returns the **exact same wrapper** 100 times. `anon` is best used for nested functions as `anon`-imized functions are added in the object's `Context.Includes` (a map that tells the `StackSpider` it's part of the object).

**Usage Example:**
```luau
function MyClass:DoSomething()
    local nestedInner = anon(function()
        local deeperInner = anon(function()
            print(self.Message) -- the StackSpider will only hit deeperInner instead of DoSomething, reducing the amount of crawling it has to do
        end)
    end)
end
```

!!! warning "The Upvalue Trap: Shadowing"
    Because `anon` caches the wrapper based on its location in the script, the **upvalues** (local variables from the outer scope) are captured only once, which was during the very first call. Subsequent calls will use those original, **stagnant** values.

    To prevent logic poisoning, you should **pass dependencies as parameters** (Shadowing).
    ```luau
    function MyClass:BadAnonUsage()
        local old, cur = math.random(1, 5), math.random(1, 5)
        -- First Call: 2, 5
        -- Second Call: 5, 3
        local nestedInner = anon(function()
            local deeperInner = anon(function()
                print(old + cur)
            end)
            deeperInner()
        end)
        nestedInner()
    end

    function MyClass:GoodAnonUsage()
        local old, cur = math.random(1, 5), math.random(1, 5)
        -- First Call: 2, 5
        -- Second Call: 5, 3
        local nestedInner = anon(function(old, cur)
            local deeperInner = anon(function(old, cur)
                print(old, cur)
            end)
            deeperInner(old, cur)
        end)
        nestedInner(old, cur)
    end
    
    MyClass:BadAnonUsage() -- 7
    MyClass:BadAnonUsage() -- 7 (BAD! Stagnant upvalues were used since anon caches the function)
    
    MyClass:GoodAnonUsage() -- 7
    MyClass:GoodAnonUsage() -- 8 (Good! Since we passed old and cur, it uses the most latest value)
    ```

### The Ephemeral Bridge: `ref`
`ref` is designed for the Roblox Engine (`RunService`, `task.spawn`, Signals). Because these engine features are **cclosures**, they strip away Luau's calling context. `ref` creates a unique wrapper and stores it in a weak-keyed `Context.Refs` table.

**Usage Example:**
```luau
MyClass(function(self: MyClass)
    task.spawn(ref(function()
        print(self.Secret) -- I'm a secret!
        -- It hits the wrapper containing the actual function before hitting the cclosure
    end))
    task.spawn(function()
        print(self.Secret) -- ERRORS! It hits the cclosure thread of spawn
    end)
end)
```

!!! question "`anon` vs `ref`: Aren't they the same?"
    No. Think of `anon` as a permanent addition to your class's identity (cached by location). Think of `ref` as a temporary security badge given to a visitor (unique every time).
   
    * Use `anon` when you want the function to be recognized as part of the class family forever.
    * Use `ref` when you are passing a callback to an external system and want it to "die" naturally when the task is done.

!!! danger "Don't swap `ref` for `friend`!"
    You might be tempted to use `friend(self, myFunc)` instead of `ref(myFunc)`. **Do not do this.** `friend` stores trust using a `string` ID of the function. **Luau cannot garbage collect those strings.** If you use `friend` for engine events, your `Context.Friends` table will grow indefinitely, leaking memory until the server crashes or until the object is destroyed with `delete`.

## `delete`: The Destroyer of `objects`
As earlier discussed on [Class Importation: The Destructor](../basics/Class%20Importation.md/#__tabbed_1_2), the `delete` function is the *"Grim Reaper"* of Ignition. It performs a deep, recursive destruction of the object to ensure no references remain in registries and caches.

1. **Inheritance Cleanup:** It climbs the tree and deletes superclasses first.
2. **Property Nuking:** It calls `free()` on every property and then sets the keys to nil.
3. **Metamethod Poisoning:** It replaces all metamethods (like `__index`) with an error thrower. This prevents *"Zombie Objects"* from being accessed after they are destroyed.
4. **Closure Purging:** It scrubs the `StackSpider`, the `anon` cache, and the `env` storage to ensure the object's code can no longer be trusted.

### The `free()` Maid
`free` is a polymorphic cleaner. It looks at the data type and chooses the best way to destroy it.

* **Instances/Connections:** Calls `:Destroy()` or `:Disconnect()`.
* **Functions:** Executes the function (treating it as a custom destructor).
* **Tables:** Recursively clears all keys and values, calling free on them as it goes.

!!! tip "The `Deleting` Guard"
    During the `delete` process, Ignition sets `environment.Deleting = true`. Because this happens before the rings are cleared, you can use it as a guard in your asynchronous code.

    If you index `self.Deleting` while an object is being destroyed, it will return `true`. This is essential for preventing *"ghost logic"* from running on a partially destroyed object.

    ``` luau
    task.delay(1, ref(function()
        if self.Deleting then return end -- Object is dying, stop logic!
        self:Update()
    end))
    ```