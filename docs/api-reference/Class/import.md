---
title: "import"
---
# :material-file-import: import <span class="chip chip-version">since v1.0.0</span><span class="chip">function</span>

The primary bridge between a class header and its implementation. `import` retrieves the class `Interface` and provides a proxy for defining constructors, methods, overloads, and accessing static members.

```luau
import(interface: Interface?) -> StaticClassObject
```

## Parameters

| Name | Type | Description |
| --- | --- | -- |
| `interface` | `Interface?` | Optional interface to import. If omitted, it automatically resolves the interface based on the caller script's name. |

## Returns

| Type | Description |
| --- | -- |
| `StaticClassObject` | A wriite-only proxy table (DSL) used to implement the class logic. |