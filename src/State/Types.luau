--!strict
-- State/Types.lua
local Generics = require("../Generics")

type Set<T> = Generics.Set<T>
type Omit<T, K> = Generics.Omit<T, K>

export type GraphObjectPublic<T> = {
    evaluate: (self: GraphObjectPublic<T>) -> boolean,
}
export type GraphDependencies = Set<any>

export type GraphObjectInternal<T> = {
    _dependencies: GraphDependencies,
    _dependents: GraphDependencies,
} & GraphObjectPublic<T>
export type GraphObject<T> = GraphObjectPublic<T>

type ValueMetatable<T> = {
    set: (self: ValueFull<T>, value: T) -> (),
    Destroy: (self: ValueFull<T>) -> (),
}

export type ValueFull<T> = typeof(setmetatable({} :: {
    _DANGEROUS_value: T,
    _CONSTANT_locked: boolean,
    _CONSTANT_error_msg: string?,
    _destructor: (obj: T) -> (),
} & ValueMetatable<T>, {} :: ValueMetatable<T>)) & GraphObjectInternal<T>

export type Value<T> = Omit<ValueFull<T>, {
    _DANGEROUS_value: unknown,
    _CONSTANT_locked: unknown,
    _CONSTANT_error_msg: unknown,
    _dependencies: unknown,
    _destructor: unknown,
}> & ValueMetatable<T>

export type Effect<T> = (use: (GraphObjectInternal<T>) -> T) -> ()
export type Property<T> = { }
export type Observe = () -> ()
export type CanBe<T> = Value<T> | T

return {}