---
title: "dumpsize"
---
# :material-database-search: dumpsize <span class="chip chip-version">since v2.0.0</span><span class="chip">function</span>

A diagnostic utility used to measure the current memory footprint of Ignition's internal registries. It provides a serialized string containing the entry counts for the core caches.

```luau
dumpsize(object: any?) -> string
```

## Returns

| Name | Type | Description |
| --- | -- | --- |
| `object` | `any?` | An Ignition object to be checked up when provided. |

## Returns

| Type | Description |
| --- | -- |
| `string` | A formatted summary of the internal cache sizes. |

!!! info "Usage"
    This function is primarily used for **Leak Detection** and **Performance Profiling**. If the counts for **anon** or **stackspider** (if global), or **family** or **refs** grow indefinitely during a loop, it indicates that closures are being generated without proper caching, your class is getting bloated, or that objects are not being correctly cleaned up via `delete()`.

    ---
    
    **Tracked Registries**

    `dumpsize` tracks weak tables found in `StackSpider`, `anon`, and `env`, and more to come when added.

    | Registry | Description |
    | --- | -- |
    | **stackspider (resolution)** | Count of resolved function-to-environment mappings. |
    | **stackspider (access)** | Count of cached caller-to-object visibility permissions. |
    | **env** | Total number of functions injected with data using a custom `getfenv`/`setfenv`. |
    | **anon** | Number of unique anonymous closures cached to prevent duplicate wrapping. |

    When an `object` is provided, instead of doing a global health checkup, it surgically checks `environment.Context` of the provided object.
    
    | Registry | Description |
    | --- | -- |
    | **internal (includes)** | Number of functions inserted by `anon` for that specific object or total count of class functions found in the class implementation/mixin composition. |
    | **internal (refs)** | Count of engine reference callbacks inserted by `ref`. |
    | **family** | Total number of functions inherited from parent(s). |
    | **friends** | Total number of functions friended with `friend` or `mutual` towards the class object. |