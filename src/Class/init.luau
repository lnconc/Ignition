--!strict
-- Class.lua

local abstract = require("@self/Private/abstract")
local class = require("@self/Private/class")
local extends = require("@self/Private/extends")
local final = require("@self/Private/final")
local free = require("@self/Private/free")
local import = require("@self/Private/import")
local mixin = require("@self/Private/mixin")
local new = require("@self/Private/new")
local nullable = require("@self/Private/nullable")
local once = require("@self/Private/once")
local property = require("@self/Private/property")
local reactive = require("@self/Private/reactive")
local ref = require("@self/Private/ref")
local super = require("@self/Private/super")
local union = require("@self/Private/union")
local Configuration = require("@self/Utility/Configuration")

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
    union = union,
    free = free,
    FLAGS = table.freeze(Configuration.PROPERTY_FLAGS),
    PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED,
    METADATA = Configuration.METADATA,
}

type classType = typeof(Class)
type function from(args: type): type
    local resultComponents = {}
    
    for _, component in args:components() do
        if component:is("singleton") then
            local keyVal = component:value()
            local propType = classType:readproperty(types.singleton(keyVal))
            
            if propType then
                table.insert(resultComponents, propType)
            else
                table.insert(resultComponents, types.never)
            end
        else
            table.insert(resultComponents, types.any)
        end
    end

    return types.intersectionof(unpack(resultComponents))
end

function Class.from<T>(...: T): from<T>
    local retrieved = table.pack(... :: any)
    for i = 1, retrieved.n do
        local k = retrieved[i]
        local r = Class[k]
        if not r then
            error(`unable to retrieve '{k}'`, 2)
        end
        retrieved[i] = r
    end
    return unpack(retrieved)
end

return Class