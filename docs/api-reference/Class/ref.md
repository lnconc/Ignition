---
title: "ref"
---
# :material-link-variant: ref <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>
Creates a reference bridge for callbacks passed to external `cclosures` (e.g., `RunService.Heartbeat`, `task.delay`, or Roblox Events). This informs the `StackSpider` that the resulting thread is authorized to access the object's internal rings.
```luau
ref<F>(callback: F) -> F
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `callback` | `F` | The function being passed to an external engine process. |

## Returns

| Type | Description |
| --- | -- |
| `F` | A wrapped version of the callback (in Dev Mode) or the raw callback (in Production). |