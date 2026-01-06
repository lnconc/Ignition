---
title: "extends"
---
# :material-family-tree: extends <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>

Establishes a vertical inheritance link between two classes. This is used in the header file to graft a superclass's interface onto the current definition.

```luau
extends<I>(targetOrSuperInterface: string | I) -> (fields: PropertiesFields) -> PropertiesFields
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `targetOrSuperInterface` | `string | I` | The name of the `class` to inherit from, or the `Interface` object itself. |

## Returns

| Type | Description |
| --- | -- |
| `(fields: PropertiesFields) -> PropertiesFields` | A passthrough function that wraps the class member table. |