--!strict
-- State/Types.lua
local Generics = require("../Generics")

type Omit<T, K> = Generics.Omit<T, K>

export type GraphDependencies = { [any]: boolean }

export type GraphObject<T> = setmetatable<{
    _dependencies: GraphDependencies,
    _dependents: GraphDependencies,
}, {
    __index: {
        evaluate: (self: GraphObject<T>) -> boolean,
    },
}>

export type InternalValue<T> = setmetatable<{
    _DANGEROUS_value: T,
    _CONSTANT_locked: boolean,
    _CONSTANT_error_msg: string?,
    _dependencies: GraphDependencies,
    _destructor: (() -> ())?,
}, {
    __index: {
        set: (self: InternalValue<T>, newValue: T) -> (),
        Destroy: (self: InternalValue<T>) -> (),
    },
}> & GraphObject<T>

export type Value<T> = Omit<InternalValue<T>, {
    _DANGEROUS_value: unknown,
    _CONSTANT_locked: unknown,
    _CONSTANT_error_msg: unknown,
    _dependencies: unknown,
    _destructor: unknown,
    evaluate: unknown,
    Destroy: unknown,
}>

export type Effect<T> = (use: (value: CanBe<T>) -> T, ...any) -> T
export type Data = { [any]: any }?

export type Property<T> = Omit<Value<T>, {
    set: unknown,
}>
export type Observe = () -> ()
export type CanBe<T> = Value<T> | T

return {}