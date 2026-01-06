--!native
--!strict
-- Class/Utility/encapsulate.lua

local Log = require("../../Log")
local Configuration = require("./Configuration")
local Value = require("../../State/Value")
local Types = require("../Types")
local StackSpider = require("./StackSpider")
local initialize = require("./initialize")
local ValueTypes = require("../../State/Types")
local free = require("../Libs/free")
local Registry = require("./Registry")
local Unyieldable = require("../../Unyieldable")
local xtypeof = require("./xtypeof")

type Symbol<T> = Types.Symbol<T>
type Environment = Types.Environment
type Type<V> = Types.Type<V>

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
local PLACEHOLDER = Configuration.PLACEHOLDER
local PROPERTY_FLAGS = Configuration.PROPERTY_FLAGS
local OPERATORS = {
    "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
    "__idiv", "__concat", "__len", "__eq", "__lt", "__le",
    "__call", "__tostring", "__iter"
}

local match = string.match
local WithinScope = StackSpider.WithinScope
local WithinFunction = StackSpider.WithinFunction

local function assessTypeMatching<K, V>(k: K, v: V, t: Type<V>)
    local vt = xtypeof(v)
    if vt == "symbol" and v == PLACEHOLDER then return end
    if t == "table" and type(t.match) == "function" then
        local yielded, okay = Unyieldable(t.match, v)
        if yielded then
            Log.THREAD_YIELDED:throw(2, "match()")
        elseif okay == false then
            Log.FAILED_TYPE_CHECK:throw(2, k, t.expects or "unknown", vt)
        end
    elseif t == "string" and vt ~= t then
        Log.FAILED_TYPE_CHECK:throw(2, k, t, vt)
    end
end

local function upsert<K, V>(ring: any, key: K, value: V, options: { flags: { [Symbol<string>]: boolean }, reactive: boolean, environment: Environment, type: Type<V>?, constructorContext: string? })
    local cur = ring[key]
    local reactive, environment, flags, type_, constructorContext = options.reactive, options.environment, options.flags, options.type, options.constructorContext
    if (reactive and cur and cur._DANGEROUS_value == value) or cur == value then 
        return 
    end

    if not PRODUCTION_MODE_ENABLED then
        if type_ and type_ ~= "any" then
            assessTypeMatching(key, value, type_)
        end
        local fromInit = (flags :: { FromInit: boolean }).FromInit
        local isOptional = flags[PROPERTY_FLAGS.Optional]
        local isReadonly = flags[PROPERTY_FLAGS.Readonly]
        if not isOptional and value == nil then
            if not (isReadonly and fromInit) then
                Log.REQUIRED_SET_NIL:throw(2, key)
            end
        elseif not fromInit and constructorContext ~= nil and isReadonly then
            if not WithinFunction(environment, constructorContext) then
                Log.READONLY_SET:throw(2, key)
            end
        end
    end

    if reactive then
        if not cur then
            cur = (Value.new(value, free) :: any) :: ValueTypes.InternalValue<any>
            if flags[PROPERTY_FLAGS.Constant] or (type(key) == "string" and match(key, "^[A-Z]+$") ~= nil) then
                cur._CONSTANT_locked = true
            end
            ring[key] = cur
        else
            (cur :: ValueTypes.InternalValue<any>):set(value)
        end
    else
        ring[key] = if value == nil then PLACEHOLDER else value
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
        if key == "Deleting" and environment.Deleting then return true end
        if environment.Deleting then
            Log.DELETING_STATE:throw(2, environment.Id)
        end
        if PRODUCTION_MODE_ENABLED then
            local out = data[key]
            if reactiveMap[key] and out then out:evaluate() end
            return if out == PLACEHOLDER then nil else out
        end

        local info = specifierMap[key]
        if not info then
            local super = environment.SuperClass
            if super.object then return (super.object :: any)[key] end
            Log.MISSING_PROP_INDEX:throw(2, key)
        end
        local static, specifier, reactive = info.static, info.specifier, reactiveMap[key]
        if specifier == "public" and not static and not reactive then
            return (data.public :: any)[key]
        elseif specifier ~= "public" then
            local included, protects = WithinScope(environment)
            if specifier == "private" and not included then
                Log.PRIVATE_ACCESS:throw(2, key)
            elseif specifier == "protected" and not (included or protects) then
                Log.PROTECTED_ACCESS:throw(2, key)
            end
        end

        local ring = if static then staticproperties[specifier] else data[specifier]
        local out = ring[key]
        if reactive and out then out:evaluate() end
        return if out == PLACEHOLDER then nil else out
    end

    function metatable:__newindex(key: any, value: any)
        if environment.Deleting then
            Log.DELETING_STATE:throw(2, environment.Id)
        end
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
            Log.MISSING_PROP_WRITE:throw(2, key)
        end
        local static, specifier, reactive = info.static, info.specifier, reactiveMap[key]
        if specifier == "public" and not static and (environment.PropertyFlags[key] and not next(environment.PropertyFlags[key])) then
            (data.public :: any)[key] = if value == nil then PLACEHOLDER else value
            return
        elseif specifier ~= "public" then
            local included, protects = WithinScope(environment)
            if specifier == "private" and not included then
                Log.PRIVATE_WRITE:throw(2, key)
            elseif specifier == "protected" and not (included or protects) then
                Log.PROTECTED_WRITE:throw(2, key)
            end
        end

        local ring = if static then staticproperties[specifier] else data[specifier]
        upsert(ring, key, value, {
            flags = environment.PropertyFlags[key] or {},
            reactive = reactive,
            environment = environment,
            type = environment.PropertyTypes[key],
            constructorContext = if environment.Context then environment.Context.Constructor else nil,
        })
    end

    -- create a template __iter
    metatable.__iter = function()
        if environment.Deleting then
            Log.DELETING_STATE:throw(2, environment.Id)
        end
        
        local keys = {}
        if PRODUCTION_MODE_ENABLED then
            for k, _ in pairs(data) do table.insert(keys, k) end
        else
            local included, protected = WithinScope(environment)
            for k, _ in pairs(data.public) do table.insert(keys, k) end
            if included or protected then
                for k, _ in pairs(data.protected) do table.insert(keys, k) end
            end
            if included then
                for k, _ in pairs(data.private) do table.insert(keys, k) end
            end
        end
        local index = 0
        local count = #keys
        return function()
            index += 1
            if index <= count then
                local key = keys[index]
                return key, object[key]
            end
        end
    end

    for _, op in ipairs(OPERATORS) do
        local impl = interface.closures[op]
        if not impl then continue end

        if PRODUCTION_MODE_ENABLED then
            metatable[op] = impl
        else
            metatable[op] = function(a, b)
                if environment.Deleting then
                    Log.DELETING_STATE:throw(2, environment.Id)
                end
                local info = specifierMap[op]
                local specifier = info.specifier or "public"
                if info and specifier ~= "public" then
                    local inc, prot = WithinScope(environment)
                    if not (inc or (specifier == "protected" and prot)) then
                        Log.OPERATOR_VIOLATION:throw(2, op, specifier)
                    end
                end
                return (impl :: any)(a, b)
            end
        end
    end

    Registry.LinkData(object, data)
end

return encapsulate