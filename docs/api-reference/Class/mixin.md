---
title: "mixin"
---
# :material-vector-combine: mixin <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>
Performs horizontal composition by harvesting properties and closures from existing components and grafting them onto a new class definition. Unlike inheritance, a `mixin` performs a field-level copy.

```luau
mixin(name: string) -> <I>(...string | I) -> (mixin_fields: PropertiesFields) -> Interface
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `name` | `string` | The unique name for the new composite `class`. |
| `...` | `string | I` | A variadic list of component names or interfaces to be included. |
| `mixin_fields` | `PropertiesFields` | The authoritative property fields of the specific composite class. |


## Returns

| Type | Description |
| --- | -- |
| `Interface` | The composite `class`'s interface. |