--!nocheck
-- Internal/env.lua

local Types = require(script.Parent.Types)

type Closure = Types.Closure
type Environment<K, V> = Types.Environment<K, V>

return {
    set = function(closure: Closure?, registry: Environment<any, any>)
        if not closure then return end
        assert(next(registry), "empty modified registry")
        local originalEnvironment = getfenv(closure)
        setfenv(closure, setmetatable(registry, { __index = originalEnvironment }))
    end,
    get = function(closure): Environment<any, any>
        return getfenv(closure)
    end
}