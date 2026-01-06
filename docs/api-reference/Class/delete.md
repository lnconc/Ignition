---
title: "delete"
---
# :material-delete-forever: delete <span class="chip chip-version">since v2.1.0</span><span class="chip">function</span>
The primary destructor for Ignition objects. It performs a recursive deep-purge of the object, its superclasses, and all associated memory registries.
```luau
delete(object: any) -> ()
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `object` | `any` | The Ignition instance to be destroyed. |
