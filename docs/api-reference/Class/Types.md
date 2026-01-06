---
title: "Types"
---
# :material-shield-check: Types <span class="chip chip-version">since v1.0.0</span><span class="chip">Reference</span>

This page documents the internal type definitions and type-level functions used to drive Ignition's static analysis and runtime validation.

## Core Structure Types

### `Interface`
The static definition of a class as stored in the `Registry`.
```luau
export type Interface = setmetatable<{
    name: string,
    staticproperties: PropertiesFields,
    properties: PropertiesFields,
    flags: {
        AllowReactivity: boolean,
        ClassFinalized: boolean,
        ClassAbstracted: boolean,
        InheritanceLinked: boolean,
    },
    closures: { [string]: OverloadFunction? },
    constructor: {
        defined: boolean,
        callback: OverloadFunction?,
    },
    virtuals: { [string]: boolean },
    superclass: Interface?,
    instantiate: <A...>(self: Interface, fromDerivedClass: boolean, fromInit: boolean, A...) -> (any, Environment),
}, { __metatable: string }>
```

### `Environment`
The internal state object mapped to every unique object instance.
```luau
export type Environment = {
    Context: {
        Includes: { [string]: boolean },
        Refs: setmetatable<{ [typeof(function() end)]: boolean }, { __mode: string }>,
        Friends: { [string]: boolean },
        Family: { [string]: { [string]: boolean } },
        Constructor: string,
    },
    PropertyTypes: { [string]: string },
    PropertyFlags: { [string]: { [Symbol<string>]: boolean } },
    Id: Symbol<string>,
    Interface: Interface,
    Closures: { any },
    Deleting: boolean,
    Metatable: any,
    Master: any?,
    SuperClass: {
        object: any?,
        environment: any?,
    },
}
```

## Type Functions (Static Analysis)
Ignition uses Luau Type Functions to transform class headers into usable object types during development.

### `GetClassObject<I, A>`
Iterates through an `Interface` and filters members based on the `accessLevel` (`Public`, `Protected`, `Private`). It transforms `property` and `func` descriptors into raw Luau types.

### `ImportedClassObject<G>`
The type-level equivalent of the `import()` call. It converts a raw `GetClassObject` result into a DSL proxy. It rebinds `self` to the first argument of non-static methods. Additionally, it maps the `ImportedClassObject` to a `StaticClassObject` when `__complete__` is called.

### `StaticClassObject<O>`
The mapped `ImportedClassObject` which reuses the `GetClassObjec` result to map public static `properties` and `funcs` instead.

### `MergeInterfaces<L>`
Drives the `mixin` system. It accepts a list of `Interfaces` and performs a type-level merge of their visibility rings, allowing the type solver to recognize members from all combined components.

### `InheritFields<S, J>`
Drives the `extends` system. It grafts the properties of the `superInterface` into the new class fields, ensuring that the child class *"sees"* the protected members of the parent.

## Extra Structure Types
### `FinalProperty<V, T, D>`
Final state of a `property` or `func`.
```luau
export type FinalProperty<V, T, D> = {
    type: T,
    value: V,
    dummy: D,
    flags: { Symbol<string> } | { [Symbol<string>]: boolean },
    _signature: string,
}
```
### `PropertyField`
```luau
export type PropertyField = { [string]: any }
```
### `PropertiesFields`
```luau
export type PropertiesFields = {
    public: PropertyField,
    protected: PropertyField,
    private: PropertyField,
    [string]: any,
}
```
### `Expects`
```luau
export type Expects = { string | Nullable<string | Union<string>> | Union<string> }
```
### `OverloadEntry`
```luau
export type OverloadEntry = { callback: AnyFunction, expects: Expects }
```
### `OverloadRecord`
```luau
export type OverloadRecord = {
    isOverloaded: boolean,
    overloads: { OverloadEntry },
    fallback: AnyFunction
}
```
### `Symbol`
```luau
export type Symbol<T> = setmetatable<{}, {
    __tostring: () -> string,
    __metatable: T,
    __call: () -> (),
}>
```
## Other Types

```luau
export type OverloadFunction = OverloadRecord | AnyFunction
export type Function = <A..., R...>(A...) -> R... | () -> ()
export type ClassFunction = <A..., R...>(self: any, A...) -> R...
export type AnyFunction = ClassFunction | Function
export type PropertyExposure = "shared" | "client" | "server"
```