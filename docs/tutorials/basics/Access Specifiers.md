# Access Specifiers

On the previous pages (*Classes and Objects* and *Tutorials*), you may have noticed in our `fields` structure, it contains the fields such as `public`, `private`, and `protected`.

In Ignition, **Access Specifiers** are the <u>rules of engagement</u> for your class data. They define who is allowed to see or modify a member, enforced at runtime by library internals such as the `StackSpider` and our custom `env`.

By categorizing members into these three scopes, you create a *"blackbox"* architecture, exposing only what is necessary and protecting the internal state of your logic.

=== "Public Access Specifier"
    The `public` specifier is the *front door* of your class. Members defined here are accessible from anywhere in your project.

    ```luau
    class "Entity" {
        public = {
            Health = 100
        }
    }

    -- Accessible from an external script
    print(entity.Health) -- 100
    ```
=== "Private Access Specifier"
    The `private` specifier is *top secret*. These members are strictly encapsulated within the specific class that defined them. Not even children can see them.
    [Friended functions](../advanced/Friends.md) can also access `private` members so long as it was explicitly defined.

    ```luau
    class "Entity" {
        private = {
            CurrentState = "Idle"
        }
    }

    -- Some external script or line of code
    print(entity.CurrentState) -- ERROR (attempt to access private property "CurrentState")
    ```

=== "Protected Access Specifier"
    The protected specifier is for *"Family Members Only."* These members are hidden from the outside world but are shared with any class that inherits from this one.
    
    ```luau
    class "Entity" {
        protected = {
            Move = func {}
        }
    }
    -- Some derived class
    entity:Move(Vector3.new(0, 0, 10)) -- Moves by 10 studs on the +Z Axis
    -- Some external script or line of code
    entity:Move(Vector3.new(0, 0, 10)) -- ERRORS (attempt to access protected property "Move")
    ```

    !!! note Matryoshka Access
        Child `classes` can read/write `protected` properties of their parents, however, parent `classes` themselves cannot view the `protected` or `private` members of their children themselves!

        Access flows **up** the inheritance chain, never **down.**


**Summary of Permissions**

| Accessor | Public | Protected | Private |
| --- | --- | --- | --- |
| Same Class | ✅ | ✅ | ✅ |
| Derived (Child) Class | ✅ | ✅ | ❌ |
| External Scripts | ✅ | ❌ | ❌ |

!!! info "Access vs. Exposure"
    You might later learn about the `exposure` field of the functions `property` and `func` (concepts later discussed).
    
    The difference between the two is that `exposure` is about **Network Visibility** (if the member can be visible on that network context, i.e., you only want the `Accessories` property of an `Entity` appear on the `client`), having `server`, `client`, and `shared`.