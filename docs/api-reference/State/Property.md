---
title: Property
---
# :material-calculator: Property <span class="chip chip-version">since v1.0.0</span><span class="chip">computed</span>
A `Property` represents a value derived from other reactive atoms. It automatically re-calculates whenever any `Value` or `Property` it depends on changes.
```luau
Property<T>(effect: (use: (value: T | Value<T>) -> T, ...any) -> T) -> T, data: {[any]: any}?) -> Property<T>
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `effect` | `(use: (value: T | Value<T>) -> T, ...any) -> T` | The side effect that gets called when one of its dependencies gets updated. |
| `data` | `{[any]: any}?` | Optional. External data to be passed to `effect`. |

## Returns
| Type | Description |
| --- | --- |
| `Property<T>` | The returned `Property` object. |