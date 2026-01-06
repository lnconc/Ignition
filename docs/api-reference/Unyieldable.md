---
title: Unyieldable
---
# :material-timer-off: Unyieldable <span class="chip chip-version">since v2.1.0</span><span class="chip">utility</span>
`Unyieldable` is a thread-safety wrapper used to execute functions that must remain synchronous. It is heavily used in the reactivity engine to ensure that state evaluations and type checks do not suspend the main execution thread.
```luau
Unyieldable(fn: (...any) -> ...any, ...any) -> (boolean, ...any)
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `fn` | `(...any) -> ...any` | The function to be executed in a non-yielding context. |
| `...` | `any` | Arguments to be passed to the function. |

## Returns
| Type | Description |
| --- | --- |
| `boolean` | Returns `true` if the function attempted to yield (suspend), or `false` if it completed normally. |
| `...any` | If the function completed, returns the function results. If it yielded, returns *"coroutine suspended"*. |