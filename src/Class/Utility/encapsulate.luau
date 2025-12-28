--!native
--!strict
-- Class/Utility/encapsulate.lua

local Configuration = require("./Configuration")
local Symbol = require("../../Modules/Symbol")
local Unyieldable = require("../../Modules/Unyieldable")
local Value = require("../../State/Value")
local Types = require("../Types")
local StackSpider = require("./StackSpider")
local initialize = require("./initialize")
local ValueTypes = require("../../State/Types")
local free = require("../Libs/free")
local is_property = require("./is_property")

type Properties = Types.Properties
type PropertyRaw<P> = Types.PropertyRaw<P>
type Environment = Types.Environment
type TypeCheck = string | <V>(value: V) -> boolean
type SerializedProperties = Types.SerializedProperties
type InternalObject = Types.InternalObject<Properties>
type BaseObject = Types.BaseObject<Properties>
type Function = Types.Function
type Set<T> = Types.Set<T>

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
local NULL_PLACEHOLDER = Symbol("null")
local PROPERTY_FLAGS = Configuration.PROPERTY_FLAGS
local OPERATORS = {
    "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
    "__idiv", "__concat", "__len", "__eq", "__lt", "__le",
    "__call", "__tostring", "__iter"
}

local match = string.match
local WithinScope = StackSpider.WithinScope
local WithinFunction = StackSpider.WithinFunction

local function run_enforced_typecheck<V>(value: V, typeCheck: TypeCheck?): boolean
    if type(typeCheck) == "string" then
        return typeof(value) == typeCheck
    elseif type(typeCheck) == "function" then
        return Unyieldable(typeCheck, value)
    end
    return true
end

local function upsert<K, V>(ring: any, key: K, value: V, flags: any, enforcedTypeOrPredicate: TypeCheck?, build_contexts: Set<string>?, environment: Environment?)
    local cur = ring[key]
    if (flags.allowReactivity and cur and cur._DANGEROUS_value == value) or cur == value then 
        return 
    end
    
    if not PRODUCTION_MODE_ENABLED then
        if enforcedTypeOrPredicate ~= nil and not run_enforced_typecheck(value, enforcedTypeOrPredicate) then
            error(`change of property '{key}' failed to pass type check test`, 2)
        end
        if not flags[PROPERTY_FLAGS.Optional] and value == nil then
            error(`cannot set nil to required property '{key}'`, 2)
        elseif build_contexts ~= nil and environment and flags[PROPERTY_FLAGS.Readonly] and not WithinFunction(environment, build_contexts :: any) then
            error(`cannot set readonly property '{key}'`, 2)
        end
    end

    if flags.allowReactivity or flags[PROPERTY_FLAGS.Reactive] then
        if not cur then
            cur = (Value.new(value, free) :: any) :: ValueTypes.ValueFull<any>
            if flags[PROPERTY_FLAGS.Constant] or (type(key) == "string" and match(key, "^[A-Z]+$") ~= nil) then
                cur._CONSTANT_locked = true
                cur._CONSTANT_error_msg = `cannot set constant property '{key}'`
            end
            ring[key] = cur
        else
            cur:set(value)
        end
    else
        ring[key] = if value == nil then NULL_PLACEHOLDER else value
    end
end

local function encapsulate(object: any, metatable: any, environment: Environment, properties: Properties)
    local interface = environment.Interface
    local globals = interface.globals
    local allowReactivity = environment.Flags.AllowReactivity
    local allowReactivityHash = { allowReactivity = allowReactivity }

    local data = if PRODUCTION_MODE_ENABLED then {} else { public = {}, private = {}, protected = {} }
    initialize(object, environment, data, properties, upsert)

    local specifierMap = {}
    if not PRODUCTION_MODE_ENABLED then
        for specifier, field in pairs(properties) do
            for key, property in pairs(field) do
                local isStatic = if is_property(property) then property.flags and property.flags[PROPERTY_FLAGS.Static] else false
                specifierMap[key] = { specifier = specifier, static = isStatic }
            end
        end
    end

    function metatable:__index(key: any): any
        if PRODUCTION_MODE_ENABLED then
            local out = data[key]
            if allowReactivity and out then out:evaluate() end
            return if out == NULL_PLACEHOLDER then nil else out
        end

        local info = specifierMap[key]
        if not info then
            local super = environment.SuperClass
            if super.object then return super.object[key] end
            error(`attempt to index missing property '{key}'`, 2)
        end
        local static, specifier = info.static, info.specifier
        if specifier == "public" and not static and not allowReactivity then
            return data.public[key]
        elseif specifier ~= "public" then
            local included, protects = WithinScope(environment)
            if specifier == "private" and not included then
                error(`attempt to access private property '{key}'`, 2)
            elseif specifier == "protected" and not (included or protects) then
                error(`attempt to access protected property '{key}'`, 2)
            end
        end

        local ring = if static then globals[specifier] else data[specifier]
        local out = ring[key]
        local flags = environment.PropertyFlags[key]
        if (allowReactivity or flags[PROPERTY_FLAGS.Reactive]) and out then out:evaluate() end
        return if out == NULL_PLACEHOLDER then nil else out
    end

    function metatable:__newindex(key: any, value: any)
        if PRODUCTION_MODE_ENABLED then
            upsert(data, key, value, allowReactivityHash)
            return
        end

        local info = specifierMap[key]
        if not info then
            local super = environment.SuperClass
            if super.object then super.object[key] = value; return end
            error(`attempt to write missing property '{key}'`, 2)
        end
        local static, specifier = info.static, info.specifier
        if specifier == "public" and not static and not allowReactivity then
            data.public[key] = if value == nil then NULL_PLACEHOLDER else value
            return
        elseif specifier ~= "public" then
            local included, protects = WithinScope(environment)
            if (specifier == "private" and not included) or (specifier == "protected" and not (included or protects)) then
                error(`attempt to write {specifier} property '{key}' {if environment.Master then `(from {environment.Master.Interface.name})` else nil}`, 2)
            end
        end

        local ring = if static then globals[specifier] else data[specifier]
        upsert(ring, key, value, environment.PropertyFlags[key], environment.PropertyTypes[key], environment.Context.Constructor, environment)
    end

    for _, op in ipairs(OPERATORS) do
        local impl = interface.closures[op]
        if not impl then continue end

        if PRODUCTION_MODE_ENABLED then
            metatable[op] = impl
        else
            metatable[op] = function(a, b)
                local info = specifierMap[op]
                local specifier = info.specifier or "public"
                if info and specifier ~= "public" then
                    local inc, prot = WithinScope(environment)
                    if not (inc or (specifier == "protected" and prot)) then
                        error(`Operator {op} access violation`, 2)
                    end
                end
                return (impl :: Function)(a, b)
            end
        end
    end
end

return encapsulate