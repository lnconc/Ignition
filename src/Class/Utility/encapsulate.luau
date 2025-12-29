--!native
--!strict
-- Class/Utility/encapsulate.lua

local Configuration = require("./Configuration")
local Symbol = require("../../Modules/Symbol")
local Value = require("../../State/Value")
local Types = require("../Types")
local StackSpider = require("./StackSpider")
local initialize = require("./initialize")
local ValueTypes = require("../../State/Types")
local free = require("../Libs/free")

type Symbol<T> = Types.Symbol<T>
type Environment = Types.Environment

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

local function upsert<K, V>(ring: any, key: K, value: V, options: { flags: { [Symbol<string>]: boolean }, reactive: boolean, environment: Environment, type: string?, constructorContext: string? })
    local cur = ring[key]
    local reactive, environment, flags, type_, constructorContext = options.reactive, options.environment, options.flags, options.type, options.constructorContext
    if (reactive and cur and cur._DANGEROUS_value == value) or cur == value then 
        return 
    end
    
    if not PRODUCTION_MODE_ENABLED then
        if type_ and typeof(value) ~= type_ then
            error(`change of property '{key}' failed to pass type check test`, 2)
        end
        if not flags[PROPERTY_FLAGS.Optional] and value == nil then
            error(`cannot set nil to required property '{key}'`, 2)
        elseif constructorContext ~= nil and flags[PROPERTY_FLAGS.Readonly] and not WithinFunction(environment, constructorContext) then
            error(`cannot set readonly property '{key}'`, 2)
        end
    end

    if reactive then
        if not cur then
            cur = (Value.new(value, free) :: any) :: ValueTypes.InternalValue<any>
            if flags[PROPERTY_FLAGS.Constant] or (type(key) == "string" and match(key, "^[A-Z]+$") ~= nil) then
                cur._CONSTANT_locked = true
                cur._CONSTANT_error_msg = `cannot set constant property '{key}'`
            end
            ring[key] = cur
        else
            (cur :: ValueTypes.InternalValue<any>):set(value)
        end
    else
        ring[key] = if value == nil then NULL_PLACEHOLDER else value
    end
end

local function encapsulate(object: any, metatable: any, environment: Environment)
    local interface = environment.Interface
    local staticproperties = interface.staticproperties

    local data = if PRODUCTION_MODE_ENABLED then {} else { public = {}, private = {}, protected = {} }
    initialize(object, environment, data, upsert)

    local reactiveMap: { [string]: boolean } = {}
    local specifierMap: { [string]: { specifier: string, static: boolean } } = {}
    local function isReactive(key: string): boolean
        local flags = environment.PropertyFlags[key]
        return (flags and flags[PROPERTY_FLAGS.Reactive]) or interface.flags.AllowReactivity
    end

    for specifier, field in pairs(interface.properties) do
        for key in pairs(field :: { [string]: any }) do
             if not PRODUCTION_MODE_ENABLED then
                specifierMap[key] = { specifier = specifier, static = (environment.PropertyFlags[key] and environment.PropertyFlags[key][PROPERTY_FLAGS.Static] ~= nil) }
            end
            reactiveMap[key] = isReactive(key)
        end
    end

    function metatable:__index(key: any): any
        if PRODUCTION_MODE_ENABLED then
            local out = data[key]
            if reactiveMap[key] and out then out:evaluate() end
            return if out == NULL_PLACEHOLDER then nil else out
        end

        local info = specifierMap[key]
        if not info then
            local super = environment.SuperClass
            if super.object then return (super.object :: any)[key] end
            error(`attempt to index missing property '{key}'`, 2)
        end
        local static, specifier, reactive = info.static, info.specifier, reactiveMap[key]
        if specifier == "public" and not static and not reactive then
            return (data.public :: any)[key]
        elseif specifier ~= "public" then
            local included, protects = WithinScope(environment)
            if specifier == "private" and not included then
                error(`attempt to access private property '{key}'`, 2)
            elseif specifier == "protected" and not (included or protects) then
                error(`attempt to access protected property '{key}'`, 2)
            end
        end

        local ring = if static then staticproperties[specifier] else data[specifier]
        local out = ring[key]
        if reactive and out then out:evaluate() end
        return if out == NULL_PLACEHOLDER then nil else out
    end

    function metatable:__newindex(key: any, value: any)
        if PRODUCTION_MODE_ENABLED then
            upsert(data, key, value, {
                flags = environment.PropertyFlags[key] or {},
                reactive = reactiveMap[key],
                environment = environment,
                type = environment.PropertyTypes[key],
                constructorContext = environment.Context and environment.Context.Constructor or nil,
            })
            return
        end

        local info = specifierMap[key]
        if not info then
            local super = environment.SuperClass
            if super.object then (super.object :: any)[key] = value; return end
            error(`attempt to write missing property '{key}'`, 2)
        end
        local static, specifier, reactive = info.static, info.specifier, reactiveMap[key]
        if specifier == "public" and not static and not reactive then
            (data.public :: any)[key] = if value == nil then NULL_PLACEHOLDER else value
            return
        elseif specifier ~= "public" then
            local included, protects = WithinScope(environment)
            if (specifier == "private" and not included) or (specifier == "protected" and not (included or protects)) then
                error(`attempt to write {specifier} property '{key}' {if environment.Master then `(from {environment.Master.Interface.name})` else nil}`, 2)
            end
        end

        local ring = if static then staticproperties[specifier] else data[specifier]
        upsert(ring, key, value, {
            flags = environment.PropertyFlags[key],
            reactive = reactive,
            environment = environment,
            type = environment.PropertyTypes[key],
            constructorContext = environment.Context and environment.Context.Constructor or nil,
        })
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
                return (impl :: any)(a, b)
            end
        end
    end
end

return encapsulate