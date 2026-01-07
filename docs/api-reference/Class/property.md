---
title: "property"
---
# :material-pill: property <span class="chip chip-version">since v1.0.0</span><span class="chip">descriptor</span>
Defines a stateful class member with strict metadata, including type definitions, default values, and environment exposure.
```luau
property<V, T, P>(options: {
    type: T,
    value: V,
    flags: { Symbol },
    exposure: PropertyExposure?
    get: P,
    set: <P>(value: P, this: V) -> P,
}) -> FinalProperty<V, T>?
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
| `options` | `{ exposure: "shared" | "server" | "client", flags: { Symbol }, type: string, value: any, get: (this: any) -> any, set: (value: any, this: any) -> () }` |
