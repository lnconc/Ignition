---
title: Observe
---
# :material-eye: Observe <span class="chip chip-version">since v2.1.0</span><span class="chip">effect</span>
`Observe` is used to trigger side effects (like updating a UI or playing a sound) in response to state changes. Unlike `Property`, it does not return a value; instead, it returns a `cleanup` function.
```luau
Observe(effect: (use: (value: T | Value<T>) -> T, ...any) -> T) -> T, data: {[any]: any}?) -> () -> ()
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `effect` | `(use: (value: T | Value<T>) -> T, ...any) -> T` | The side effect that gets called when one of its dependencies gets updated. |
| `data` | `{[any]: any}?` | Optional. External data to be passed to `effect`. |

## Returns
| Type | Description |
| --- | --- |
| `() -> ()` | A cleanup function that destroys itself. |