---
title: "class"
---
# :material-cube-outline: class <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>
The entry point for defining an Ignition class. It initializes a unique class `Interface` and registers it within the global `Registry`.
```luau
class(name: string) -> (fields: PropertiesFields) -> Interface
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `name` | `string` | An unique name for the `class`. |
| `fields` | `PropertiesFields` | Property fields to be initialized. |

## Returns

| Type | Description |
| --- | -- |
| `Interface` | The `class`'s interface. |