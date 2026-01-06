---
title: Symbol
---
# :material-identifier: Symbol <span class="chip chip-version">since v1.0.0</span><span class="chip">primitive</span>
`Symbol` provides a way to create unique, immutable, and non-forgeable identifiers. In Ignition, these are used to protect internal metadata and create unique keys that cannot be accidentally overwritten by user-defined properties.

Symbols in Ignition use `newproxy(true)` to ensure that even if two symbols are created with the same name, they are never equal in memory.
Consequentially, the `id` is stored in the `__metatable` field, making it retrievable by the engine while remaining locked from standard Luau scripts. *Unless you're daring to access it.*
```luau
Symbol(id: T) -> Symbol<T>
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `id` | `T` | The identifier for the symbol (usually a string). This is stored in the metatable. |

## Returns
| Type | Description |
| --- | --- |
| `Symbol<T>` | A unique userdata proxy that acts as a distinct key in tables. |

