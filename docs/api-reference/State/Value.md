---
title: Value
---
# :material-variable: Value <span class="chip chip-version">since v1.0.0</span><span class="chip">state</span>

A `Value` is a reactive container. When its content is updated via `set()`, it automatically triggers a re-evaluation of all dependent reactive objects.

``` luau
Value.new<T>(defaultValue: T, destructor: (obj: T) -> ()?) -> Value<T>
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `defaultValue` | `T` | The initial data to store. |
| `destructor` | `(T) -> ()?` | Optional. A cleanup function called when the `Value` is destroyed. |

!!! info "Automatic Destructor Warning"
    If you wrap a Roblox `Instance` or a table with a metatable but do not provide a `destructor`, Ignition will issue an `INST_WRAPPER_NO_DEST` warning. This is to prevent *"zombie instances"* where a `Value` is destroyed but the underlying object remains in memory.

## Methods
### `set(value: T)`
Updates the internal data. If the new value is identical to the current value, the update is ignored to prevent unnecessary re-computations.
!!! note
    If the value was marked as `Constant` via `_CONSTANT_locked`, this will throw a `CONSTANT_SET` error.

### `evaluate()`
Used internally by the dependency graph. For a base `Value`, this always returns true as it is a root source of truth.

### `Destroy()`
Cleans up the reactive object. By calling this it will:

* Executes the `destructor` on the current value if provided.
* Severs all connections to dependents such as `Property` and `Observe`.
* Clears the internal table to prevent memory leaks.