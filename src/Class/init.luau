--!strict
-- Class.lua

local abstract = require("@self/Libs/abstract")
local class = require("@self/Libs/class")
local extends = require("@self/Libs/extends")
local final = require("@self/Libs/final")
local free = require("@self/Libs/free")
local import = require("@self/Libs/import")
local mixin = require("@self/Libs/mixin")
local new = require("@self/Libs/new")
local nullable = require("@self/Libs/nullable")
local once = require("@self/Libs/once")
local property = require("@self/Libs/property")
local reactive = require("@self/Libs/reactive")
local ref = require("@self/Libs/ref")
local super = require("@self/Libs/super")
local func = require("@self/Libs/func")
local union = require("@self/Libs/union")
local Configuration = require("@self/Utility/Configuration")

export type class = typeof(class)
export type extends = typeof(extends)
export type abstract = typeof(abstract)
export type final = typeof(final)
export type mixin = typeof(mixin)
export type import = typeof(import)
export type ref = typeof(ref)
export type super = typeof(super)
export type property = typeof(property)
export type new = typeof(new)
export type reactive = typeof(reactive)
export type once = typeof(once)
export type nullable = typeof(nullable)
export type union = typeof(union)
export type free = typeof(free)
export type func = typeof(func)
export type FLAGS = typeof(Configuration.PROPERTY_FLAGS)
export type METADATA = typeof(Configuration.METADATA)
export type PLACEHOLDER = typeof(Configuration.PLACEHOLDER)
export type PRODUCTION_MODE_ENABLED = boolean

local Class = {
    extends = extends,
    class = class,
    abstract = abstract,
    final = final,
    mixin = mixin,
    import = import,
    ref = ref,
    super = super,
    property = property,
    new = new,
    reactive = reactive,
    once = once,
    nullable = nullable,
    func = func,
    union = union,
    free = free,
    PLACEHOLDER = Configuration.PLACEHOLDER,
    FLAGS = table.freeze(Configuration.PROPERTY_FLAGS),
    PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED,
    METADATA = Configuration.METADATA,
}

function Class.from(...): ...any
    local retrieved = table.pack(...)
    for i = 1, retrieved.n do
        local k = retrieved[i]
        local r = Class[k]
        if not r then
            error(`unable to retrieve '{k}'`, 2)
        end
        retrieved[i] = r
    end
    return table.unpack(retrieved)
end

return Class