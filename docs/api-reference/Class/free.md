---
title: "free"
---
# :material-memory: free <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>
A universal garbage collection helper that attempts to safely release resources from any data type, including `Instances`, `Connections`, and nested `tables`.
```luau
free(item: any) -> ()
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `item` | `any` | The item to be released/disconnected/destroyed. |