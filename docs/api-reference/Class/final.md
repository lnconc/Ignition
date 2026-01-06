---
title: "final"
---
# :material-lock: final <span class="chip chip-version">since v1.0.0</span><span class="chip">modifier</span>
Prevents the interface from being used as a superclass. Any attempt to use extends or mixin on a final class will result in a runtime error.
```luau
final<I>(interface: I) -> I
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `interface` | `I` | The interface to be finalized. |

## Returns

| Type | Description |
| --- | -- |
| `I` | The interface itself; a passthrough return. |