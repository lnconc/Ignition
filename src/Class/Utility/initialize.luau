--!strict
-- Class/Utility/initialize.lua

local Configuration = require("./Configuration")
local env = require("../../Internal/env")
local Property = require("../../State/Property")
local Types = require("../Types")
local getOverloadedFunction = require("./getOverloadedFunction")
local is_property = require("./is_property")

type FieldsOption = Types.FieldsOption
type FieldOptions = Types.FieldOptions
type SerializedProperties = Types.SerializedProperties
type Properties = Types.Properties
type Environment = Types.Environment
type PropertyRaw<P> = Types.PropertyRaw<P>
type InternalObject = Types.InternalObject<Properties>
type Function = Types.Function

local PROPERTY_FLAGS = Configuration.PROPERTY_FLAGS
local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local function normalize_flags_once(container: any, key: string): (any?, any)
    local item = container[key]
    if type(item) ~= "table" then return nil, item end
    
    local field_flags = item.flags
    if field_flags and #field_flags > 0 then 
        local map = {}
        for _, value in ipairs(field_flags) do
            map[value] = true
        end
        field_flags = map
        item.flags = field_flags
    end
    
    return field_flags, item
end

local function shadow_map_from_array(target: { [any]: any }, source: { [any]: any }?)
    if not source then return target end
    for k, v in pairs(source) do
        if type(k) ~= "number" then
            target[k] = v
        end
    end
    return target
end

local function initialize(
    object: InternalObject, 
    environment: Environment,
    lookup: any, 
    properties: Properties, 
    upsert: any
)
    local allowReactivity = environment.Flags.AllowReactivity
    local interface = environment.Interface
    local closures = interface.closures
    local propertyFlags, propertyTypes = environment.PropertyFlags, environment.PropertyTypes
    local reactiveStatesBatch: { [any]: any } = {}

    local iterationSource = if PRODUCTION_MODE_ENABLED then properties else lookup
    for specifier, fieldOrRing in iterationSource do
        local propertyRing: FieldOptions = if PRODUCTION_MODE_ENABLED then fieldOrRing else properties[specifier]
        local destinationField = if PRODUCTION_MODE_ENABLED then lookup else fieldOrRing
        if not propertyRing then continue end
        if fieldOrRing == Configuration.METADATA then continue end
        for key, templateOrValue in pairs(propertyRing) do
            if templateOrValue == Configuration.METADATA then continue end
            local field_flags, raw = normalize_flags_once(propertyRing, key)
            local flags = shadow_map_from_array({ allowReactivity = allowReactivity }, field_flags)
            propertyFlags[key] = flags
            local t = if type(raw) == "table" then raw.type else nil
            if t then
                propertyTypes[key] = t
            end

            local is_static = field_flags and field_flags[PROPERTY_FLAGS.Static]
            local isProp = is_property(templateOrValue)
            -- reactive props
            if isProp and type(templateOrValue.effect) == "function" and reactiveStatesBatch then
                reactiveStatesBatch[templateOrValue] = { field = destinationField, key = key }
            -- functions
            elseif (isProp and templateOrValue.type == "function") or (not isProp and type(templateOrValue) == "function") then
                local closureData = closures[key]
                local fn = if type(closureData) == "table" and closureData.isOverloaded 
                    then getOverloadedFunction(key, closureData) 
                    else closureData
                fn = fn or function() error(`method {key} is unimplemented in {interface.name}`, 2) end

                local wrapper = function(...: any): any
                    if is_static then return (fn :: Function)(...) end
                    local first_arg = ...
                    local masterObject = (environment.Master :: any) or object
                    if first_arg ~= masterObject then
                        error(`invalid call signature: {key} must be called with ':' on {interface.name}`, 2)
                    end
                    return (fn :: Function)(masterObject, select(2, ...))
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
                local value = if isProp then templateOrValue.value else templateOrValue
                local source = if is_static then interface.globals[specifier] else destinationField
                upsert(source, key, value, flags, t, environment.Context.Constructor, environment)
            end
        end
    end

    for def, target in pairs(reactiveStatesBatch) do
        target.field[target.key] = Property(def.effect, def.dependencies)
    end
end

return initialize