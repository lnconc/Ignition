---
title: "abstract"
---
# :material-ghost: abstract <span class="chip chip-version">since v1.0.0</span><span class="chip">modifier</span>
Marks an interface as non-instantiable. Abstract classes serve as templates and can only be used as base classes for inheritance via `extends`.
```luau
abstract<I>(interface: I) -> I
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `interface` | `I` | The interface to be abstracted. |

## Returns

| Type | Description |
| --- | -- |
| `I` | The interface itself; a passthrough return. |