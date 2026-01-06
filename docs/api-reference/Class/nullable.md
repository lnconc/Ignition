---
title: "nullable"
---
# :material-null: nullable <span class="chip chip-version">since v1.0.0</span><span class="chip">wrapper</span>
Informs the Ignition Type Solver that a property is allowed to hold a `nil` value.
```luau
nullable(type: string | Union<string>) -> Nullable<T>
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `type` | `string | Union<string>` | The underlying type that is being marked as optional. |