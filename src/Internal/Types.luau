--!strict
-- State/Internal.luau

local Generics = require(script.Parent.Parent.Generics)

type Map<K, V> = Generics.Map<K, V>
type Array<V> = Generics.Array<V>

export type Closure = Generics.Closure
export type Environment<K, V> = Map<K, V> | Array<V>

return {}