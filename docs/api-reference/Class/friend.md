---
title: "friend"
---
# :material-account-group: friend <span class="chip chip-version">since v2.1.0</span><span class="chip">function</span>
Grants a specific *"guest"* (`function`, `class` object, or table of functions) permission to access the `private` and `protected` members of a *"subject"* object. This is a unidirectional relationship.
```luau
friend(subject: any, guest: any, methodName: string?) -> ()
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `subject` | `any` | The Ignition object instance that is granting access. |
| `guest` | `any` | The entity receiving access. Can be a function, Class Instance, or table. |
| `methodName` | `string?` | Optional. If provided alongside a class instance guest, only that specific method is friended. |