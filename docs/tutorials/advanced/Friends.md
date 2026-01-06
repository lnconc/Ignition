# Friends & Mutual Trust

In traditional OOP, your choices for member visibility are often binary: either everyone can see it (`public`), only family can see it (`protected`), or only you can see it (pri`vate).

Ignition introduces **Friends**, allowing you to grant specific external objects or functions access to your internal state without compromising your class hierarchy.

## The `friend` Helper
The `friend` function creates a one-way trust relationship. If **Object A** friends **Object B**, then **B** can see **A**'s secrets, but **A** cannot see **B**'s.

=== "Trusting an entire object"
    When you friend another object, you are trusting every method and the constructor of that object.
    ``` luau
    local player = new(PlayerClass)()
    local pet = new(PetClass)()
    -- Pet can now access player's private properties
    friend(player, pet)
    ```
=== "Trusting a Specific Method"
    This is the *least privilege* approach. You can trust a specific method by its name. This allows the guest to access your private data **only while that specific method is running.**
    ```luau
    -- Only trust the 'Sync' method of the DataManager
    friend(MyObject, DataManager, "Sync")
    ```
=== "Trusting Functions and Tables"
    You can also friend raw Luau functions or tables containing functions (like utility libraries).
    ```luau
    friend(MyObject, function()
        -- This specific closure can now touch MyObject's private fields
    end)
    ```

## `mutual` Trust
If you want two `objects` to have full access to each other's internals (a *"partnership"* relationship), use `mutual`. This is equivalent to calling `friend` twice in both directions.
```luau
local PartA = new(PhysicsObject)()
local PartB = new(PhysicsObject)()
-- Both objects can now see each other's private physics state
mutual(PartA, PartB)
```