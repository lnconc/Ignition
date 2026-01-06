---
title: "Constants"
---
# :material-variable: Constants <span class="chip">Configuration</span>

A collection of unique `Symbol` identifiers used globally by the Ignition engine to differentiate between raw data and engine-level metadata.

## Core Symbols

| Name | Type | Description |
| --- | --- | -- |
| `METADATA` | `Symbol` | The internal key used to store engine-specific data within proxies. |
| `PLACEHOLDER` | `Symbol` | A unique marker used to represent `nil` values in reactive tables or uninitialized fields. |

## Member Flags

These flags are passed into `property` or `func` descriptors to modify their behavior during the Linker phase.

| Flag | Type | Description |
| --- | --- | -- |
| `Optional` | `Symbol` | Marks a property as not required during the instantiation check. |
| `Static` | `Symbol` | Binds the member to the Class Interface rather than the object instance. |
| `Constant` | `Symbol` | Prevents the value from being changed after the class is finalized. |
| `Virtual` | `Symbol` | Explicitly allows a member to be overwritten by a `mixin` or a child class via `extends`. |
| `Readonly` | `Symbol` | Prevents writing to the property from outside the class constructor. |
| `Reactive` | `Symbol` | Forces the property to be wrapped in a `Value` object for dependency tracking. |