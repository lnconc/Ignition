--!strict
-- Class.lua

local abstract = require(script.Private.abstract)
local class = require(script.Private.class)
local extends = require(script.Private.extends)
local final = require(script.Private.final)
local free = require(script.Private.free)
local import = require(script.Private.import)
local mixin = require(script.Private.mixin)
local new = require(script.Private.new)
local nullable = require(script.Private.nullable)
local once = require(script.Private.once)
local property = require(script.Private.property)
local reactive = require(script.Private.reactive)
local ref = require(script.Private.ref)
local super = require(script.Private.super)
local union = require(script.Private.union)
local Configuration = require(script.Utility.Configuration)

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