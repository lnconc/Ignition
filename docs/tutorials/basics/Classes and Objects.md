# Classes & Objects

In Ignition, a class is a strictly defined architectural contract. It acts as a blueprint that outlines the **state (properties)** and **behavior (functions)** of a component. An object is a live instance of that blueprint, isolated and managed by `encapsulate` and the `StackSpider` to ensure memory safety and access integrity.

## Creating a Class
To create a class, you use the `Class.class` function. In Ignition, this is typically done within a `.definition` file to establish the contract before logic is ever written.

The class function requires a **Name** (`string`) and a **Fields** structure (`table`) containing access specifiers: `public`, `protected`, and `private`.
``` luau
--!strict
local Ignition = require(game.ReplicatedStorage.Ignition)

local class, property = Ignition.class, Ignition.property

local Person = class "Person" {
    public = {
        Name = "Unknown"
        Age = 0
    }
}
```

!!! tip "Inferred `public` properties"
    You don't have to explicitly write `public`, just setting properties directly onto the `fields` structure automatically passes that property *internally* as a `public` property.
    However, do note that the keys `private` and `protected` are strictly reserved for the library itself.

    ``` luau
    class "Person" {
        Name = "Testificate",  -- These two are automatically public properties
        Age = 21,
    }
    ```

## Creating an Object
To manifest a class into a live object, you use the `new` function. This allocates the object in memory and returns a "proxy" that the library now monitors.

``` luau
--!strict
local Ignition = require(game.ReplicatedStorage.Ignition)

local new = Ignition.new

local newPerson = new "Person"()
print(newPerson.Age) -- 0
```

## Updating an Object
You can update an object's members by indexing them directly.
``` luau
local newPerson = new "Person"()
newPerson.Age = 21
print(newPerson.Age) -- 21
```
!!! info
    Later on at [Class Properties](./Class Properties.md), you'll learn more features that Ignition can offer for your class properties!

### Strict Member Definition
Ignition follows the **Closed-Layout Principle.** You cannot *"hot-load"* new members onto an object after it has been created. All members **must be explicitly declared** in the class definition.

!!! danger "Architectural Violation"
    Attempting to define a new member through an object **will cause an immediate error.** This prevents *state pollution* where objects hold data that their class is unaware of.