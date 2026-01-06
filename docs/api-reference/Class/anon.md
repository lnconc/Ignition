---
title: "anon"
---
# :material-code-tags: anon <span class="chip chip-version">since v2.1.0</span><span class="chip">function</span>
Wraps an anonymous callback to ensure it is treated as an idempotent, static member of the class family. This prevents the `StackSpider` from rejecting inline closures during runtime visibility checks.
```luau
anon<F>(callback: F) -> F
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `callback` | `F` | The anonymous function to be registered and cached. |

## Returns

| Type | Description |
| --- | -- |
| `F` | A wrapped version of the callback (in Dev Mode) or the raw callback (in Production). |