---
title: "func"
---
# :material-function: func <span class="chip chip-version">since v1.2.1</span><span class="chip">descriptor</span>
Defines a method signature within a class header. It allows for explicit visibility flagging and network-based exposure filtering.
```luau
func<D>(options: { 
    exposure: PropertyExposure?, 
    flags: { Symbol },
    dummy: D 
}) -> FinalProperty<D>?
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `options` | `Options` | Options table to aid with the helper in definition |

## Returns

| Type | Description |
| --- | -- |
| `FinalProperty?` | A descriptor used by the Linker, or nil if the current environment does not match the exposure setting. |

## Types

| Name | Type |
| --- | --- |
| `options` | `{ exposure: "shared" | "server" | "client", flags: { Symbol }, dummy: (...any) -> (...any) }` |
