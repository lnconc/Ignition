---
title: "new"
---
# :material-code-tags: new <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>
The standard constructor factory for Ignition classes. It resolves a target interface and returns a closure that, when called, triggers the internal instantiation and construction sequence.
```luau
new<I>(nameOrInterface: string | I) -> (...any) -> GetClassObject<I, "Public">
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `nameOrInterface` | `string | I` | The target to instantiate. Can be a string of a class name, an `Interface` object, or the `StaticClassObject` returned by calling the imported `class` and providing `true` as your argument. |

## Returns

| Type | Description |
| --- | -- |
| `(...any) -> GetClassObject<I, "Public">` | A constructor function that accepts arguments for the class init method and returns the final object instance. |