--!strict
-- Class/Utility/initialize.lua

local Configuration = require("./Configuration")
local env = require("../../Internal/env")
local Log = require("../../Log")
local Property = require("../../State/Property")
local getOverloadedFunction = require("./getOverloadedFunction")
local is_property = require("./is_property")

local PROPERTY_FLAGS = Configuration.PROPERTY_FLAGS
local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local match = string.match

local function initialize(
    object: any, 
    environment: any,
    data: { [any]: any }, 
    upsert: any
)
    local interface = environment.Interface
    local properties, closures = interface.properties, interface.closures
    local propertyFlags, propertyTypes = environment.PropertyFlags, environment.PropertyTypes
    local reactiveStatesBatch: { [any]: any } = {}

    local iterationSource = if PRODUCTION_MODE_ENABLED then interface.properties else data
    for specifier, fieldOrRing in iterationSource do
        local propertyRing: any = if PRODUCTION_MODE_ENABLED then fieldOrRing else properties[specifier]
        local destinationField: { [any]: any } = if PRODUCTION_MODE_ENABLED then data else fieldOrRing
        if not propertyRing then continue end
        if fieldOrRing == Configuration.METADATA then continue end
        for key, templateOrValue in pairs(propertyRing :: { [any]: any }) do
            if templateOrValue == Configuration.METADATA then continue end
            local flags = propertyFlags[key]
            local is_static, is_reactive = flags and (flags :: any)[PROPERTY_FLAGS.Static], flags and (flags :: any)[PROPERTY_FLAGS.Reactive]
            local isProp = is_property(templateOrValue)
            -- reactive props
                if isProp and is_reactive and type((templateOrValue :: any).effect) == "function" and reactiveStatesBatch then
                reactiveStatesBatch[templateOrValue] = { field = destinationField, key = key }
            -- functions
            elseif (isProp and (templateOrValue :: any).type == "function") or (not isProp and type(templateOrValue) == "function") then
                if is_static and destinationField[key] ~= nil then continue end
                local closureData = closures[key]
                local fn = if type(closureData) == "table" and closureData.isOverloaded 
                    then getOverloadedFunction(key, closureData) 
                    else closureData
                fn = fn or function() Log.UNIMPLEMENTED:throw(2, key, interface.name) end

                local wrapper = function(...: any): any
                    if is_static then return (fn :: any)(...) end
                    local first_arg = ...
                    local masterObject = (environment.Master :: any) or object
                    if first_arg ~= masterObject then
                        Log.INVALID_CALL_SIG:throw(2, key, interface.name)
                    end
                    return (fn :: any)(masterObject, select(2, ...))
                end

                if not PRODUCTION_MODE_ENABLED then
                    env.set(wrapper :: any, { environment = environment })
                    local id = tostring(wrapper)
                    environment.Context.Includes[id] = true
                    local family = environment.Context.Family[interface.name] or {}
                    (family :: any)[id] = true
                    environment.Context.Family[interface.name] = family
                    table.insert(environment.Closures, wrapper)
                end
                destinationField[key] = wrapper
            -- standard props
            else
                local value = if isProp then (templateOrValue :: any).value else templateOrValue
                local source = if is_static then interface.staticproperties[specifier] else destinationField
                local tempFlags = { FromInit = true }
                if flags then
                    for flag in flags do
                        tempFlags[flag] = true
                    end
                    if type(key) == "string" and match(key, "^[A-Z]+$") then
                        tempFlags[PROPERTY_FLAGS.Constant] = true
                    end
                end
                upsert(source, key, value, {
                    flags = tempFlags,
                    reactive = interface.flags.AllowReactivity or is_reactive,
                    environment = environment,
                    type = propertyTypes[key],
                    constructorContext = if environment.Context then (environment.Context :: any).Constructor else nil,
                    set = if isProp then (templateOrValue :: any).set else nil,
                })
            end
        end
    end

    for def, target in pairs(reactiveStatesBatch) do
        target.field[target.key] = Property(def.effect, def.dependencies)
    end
end

return initialize