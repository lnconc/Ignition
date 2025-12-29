--!strict
-- Class/Utility/initialize.lua

local Configuration = require("./Configuration")
local env = require("../../Internal/env")
local Property = require("../../State/Property")
local Types = require("../Types")
local getOverloadedFunction = require("./getOverloadedFunction")
local is_property = require("./is_property")

type Environment = Types.Environment
type PropertyField = Types.PropertyField
type CanBeProperty<T> = Types.CanBeProperty<T>
type GetClassObject<P, A> = Types.GetClassObject<P, A>
type Symbol<T> = Types.Symbol<T>

local PROPERTY_FLAGS = Configuration.PROPERTY_FLAGS
local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local function initialize(
    object: any, 
    environment: Environment,
    data: { [any]: any }, 
    upsert: <K, V>(ring: any, key: K, value: V, options: { flags: { [Symbol<string>]: boolean }, reactive: boolean, environment: Environment, type: string?, constructorContext: string? }) -> ()
)
    local interface = environment.Interface
    local properties, closures = interface.properties, interface.closures
    local propertyFlags, propertyTypes = environment.PropertyFlags, environment.PropertyTypes
    local reactiveStatesBatch: { [any]: any } = {}

    local iterationSource = if PRODUCTION_MODE_ENABLED then interface.properties else data
    for specifier, fieldOrRing in iterationSource do
        local propertyRing: PropertyField = if PRODUCTION_MODE_ENABLED then fieldOrRing else properties[specifier]
        local destinationField: { [any]: any } = if PRODUCTION_MODE_ENABLED then data else fieldOrRing
        if not propertyRing then continue end
        if fieldOrRing == Configuration.METADATA then continue end
        for key, templateOrValue in pairs(propertyRing :: { [any]: any }) do
            if templateOrValue == Configuration.METADATA then continue end
            local flags = propertyFlags[key]
            local is_static = flags and flags[PROPERTY_FLAGS.Static]
            local isProp = is_property(templateOrValue :: CanBeProperty<any>)
            -- reactive props
            if isProp and type((templateOrValue :: CanBeProperty<any>).effect) == "function" and reactiveStatesBatch then
                reactiveStatesBatch[templateOrValue] = { field = destinationField, key = key }
            -- functions
            elseif (isProp and (templateOrValue :: CanBeProperty<any>).type == "function") or (not isProp and type(templateOrValue) == "function") then
                local closureData = closures[key]
                local fn = if type(closureData) == "table" and closureData.isOverloaded 
                    then getOverloadedFunction(key, closureData) 
                    else closureData
                fn = fn or function() error(`method {key} is unimplemented in {interface.name}`, 2) end

                local wrapper = function(...: any): any
                    if is_static then return (fn :: any)(...) end
                    local first_arg = ...
                    local masterObject = (environment.Master :: any) or object
                    if first_arg ~= masterObject then
                        error(`invalid call signature: {key} must be called with ':' on {interface.name}`, 2)
                    end
                    return (fn :: any)(masterObject, select(2, ...))
                end

                if not PRODUCTION_MODE_ENABLED then
                    env.set(wrapper, { environment = environment })
                    local id = tostring(wrapper)
                    environment.Context.Includes[id] = true
                    local family = environment.Context.Family[interface.name] or {}
                    family[id] = true
                    environment.Context.Family[interface.name] = family
                end
                destinationField[key] = wrapper
            -- standard props
            else
                local value = if isProp then (templateOrValue :: CanBeProperty<any>).value else templateOrValue
                local source = if is_static then interface.staticproperties[specifier] else destinationField
                upsert(source, key, value, {
                    flags = flags or {},
                    reactive = interface.flags.AllowReactivity or (flags and flags[PROPERTY_FLAGS.Reactive]) or false,
                    environment = environment,
                    type = propertyTypes[key],
                    constructorContext = environment.Context.Constructor,
                })
            end
        end
    end

    for def, target in pairs(reactiveStatesBatch) do
        target.field[target.key] = Property(def.effect, def.dependencies)
    end
end

return initialize