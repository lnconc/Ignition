---
title: "reactive"
---
# :material-flash: reactive <span class="chip chip-version">since v1.0.0</span><span class="chip">modifier</span>
Enables the Ignition Reactive State engine for the target class. This modifier ensures that all properties within the interface are automatically wrapped in dependency-tracking objects.
```luau
reactive<I>(interface: I) -> I
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `interface` | `I` | The interface to be made reactive. |

## Returns

| Type | Description |
| --- | -- |
| `I` | The interface itself; a passthrough return. |