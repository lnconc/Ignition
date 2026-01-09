--!native
--!strict
-- Class/Utility/encapsulate.lua

local Log = require("../../Log")
local Configuration = require("./Configuration")
local Value = require("../../State/Value")
local StackSpider = require("./StackSpider")
local initialize = require("./initialize")
local peek = require("../../State/peek")
local free = require("../Libs/free")
local Registry = require("./Registry")
local Unyieldable = require("../../Unyieldable")
local is_property = require("./is_property")

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
local PLACEHOLDER = Configuration.PLACEHOLDER
local PROPERTY_FLAGS = Configuration.PROPERTY_FLAGS
local OPERATORS = {
    "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
    "__idiv", "__concat", "__len", "__eq", "__lt", "__le",
    "__call", "__tostring", "__iter"
}

local WithinScope = StackSpider.WithinScope
local WithinFunction = StackSpider.WithinFunction

local function assessTypeMatching<K, V>(k: K, v: V, t: any)
    local vt = typeof(v)
    if type(t) == "table" then
        if type(t.match) == "function" then
            local yielded, okay = Unyieldable(t.match :: any, v)
            if yielded then
                Log.THREAD_YIELDED:throw(2, "match()")
            elseif okay == false then
                Log.FAILED_TYPE_CHECK:throw(2, k, t.expects or "unknown", vt)
            end
        else
            local matchFound = false
            for _, allowedType in ipairs(t) do
                local success = false
                if type(allowedType) == "string" then
                    if (vt == "Instance" and (v :: any):IsA(allowedType)) or vt == allowedType then
                        success = true
                    end
                end
                
                if success then
                    matchFound = true
                    break
                end
            end
            if not matchFound then
                local expected = table.concat(t, " | ")
                Log.FAILED_TYPE_CHECK:throw(2, k, expected, vt)
            end
        end
    elseif type(t) == "string" then
        if vt == "Instance" then
            if not (v :: any):IsA(t) then
                Log.FAILED_TYPE_CHECK:throw(2, k, t, (v :: any).ClassName)
            end
        elseif vt ~= t then
            Log.FAILED_TYPE_CHECK:throw(2, k, t, vt)
        end
    end
end

local function upsert<K, V>(ring: any, key: K, value: V, options: { flags: { [any]: boolean }, reactive: boolean, environment: any, type: any?, constructorContext: string?, set: any? })
    local cur = ring[key]
    local reactive, environment, flags, type_, constructorContext, set = options.reactive, options.environment, options.flags, options.type, options.constructorContext, options.set
    if (reactive and cur and cur._DANGEROUS_value == value) or cur == value then 
        return 
    end
    local hasSetAccessor = set ~= nil
    if not PRODUCTION_MODE_ENABLED then
        local null = value == nil or value == PLACEHOLDER
        if not hasSetAccessor and type_ ~= nil and type_ ~= "any" then
            if null then return end -- ignore type matching for now since we have our isOptional check down below
            assessTypeMatching(key, value, type_)
        end
        local fromInit = (flags :: { FromInit: boolean }).FromInit
        local isOptional = flags[PROPERTY_FLAGS.Optional]
        local isReadonly = flags[PROPERTY_FLAGS.Readonly]
        if not isOptional and null then
            if not (isReadonly and fromInit) then
                Log.REQUIRED_SET_NIL:throw(2, key)
            end
        elseif not fromInit and constructorContext ~= nil and isReadonly then
            if not WithinFunction(environment, constructorContext) then
                Log.READONLY_SET:throw(2, key)
            end
        end
    end
    if hasSetAccessor then
        local isInsideConstructor = constructorContext ~= nil and WithinFunction(environment, constructorContext)
        if not isInsideConstructor then
            local _raw = peek(cur)
            local raw = if _raw == PLACEHOLDER then nil else _raw
            value = (set :: any)(value, raw)
        end
    end
    if reactive then
        if not cur then
            cur = Value.new(value, free)
            if flags[PROPERTY_FLAGS.Constant] then
                cur._CONSTANT_locked = true
            end
            ring[key] = cur
        else
            (cur :: any):set(value)
        end
    else
        ring[key] = if value == nil then PLACEHOLDER else value
    end
end

local function encapsulate(object: any, metatable: any, environment: any)
    local interface = environment.Interface
    local staticproperties = interface.staticproperties

    local data = if PRODUCTION_MODE_ENABLED then {} else { public = {}, private = {}, protected = {} }
    initialize(object, environment, data, upsert)

    local optionsCache = {}
    local hasFlagsMap: { [string]: boolean } = {}
    local accessorMap: { [string]: { get: any, set: any }} = {}
    local reactiveMap: { [string]: boolean } = {}
    local specifierMap: { [string]: { specifier: string, static: boolean } } = {}

    local function getOptions(key: string, defaultOptions: any)
        if optionsCache[key] then return optionsCache[key] end
        optionsCache[key] = defaultOptions
        return defaultOptions
    end

    for specifier, field in pairs(interface.properties) do
        for key, value in pairs(field :: { [string]: any }) do
            local flags = environment.PropertyFlags[key]
            if is_property(value) then
                accessorMap[key] = { get = value.get, set = value.set }
            end
            if not flags then
                specifierMap[key] = { specifier = specifier, static = false }
                reactiveMap[key] = false
                hasFlagsMap[key] = false    
            continue end
            if not PRODUCTION_MODE_ENABLED then
                specifierMap[key] = { specifier = specifier, static = (flags :: any)[PROPERTY_FLAGS.Static] ~= nil }
            end
            hasFlagsMap[key] = not next(flags)
            reactiveMap[key] = (flags :: any)[PROPERTY_FLAGS.Reactive] ~= nil or interface.flags.AllowReactivity
        end
    end

    function metatable:__index(key: any): any
        if key == "Deleting" and environment.Deleting then return true end
        if environment.Deleting then
            Log.DELETING_STATE:throw(2, environment.Id)
        end
        local accessor = accessorMap[key]
        if PRODUCTION_MODE_ENABLED then
            local out = data[key]
            if reactiveMap[key] and out then out:evaluate() end
            out = if out == PLACEHOLDER then nil else out
            if accessor and accessor.get then return (accessor.get :: any)(out) end
            return out
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
        out = if out == PLACEHOLDER then nil else out
        if accessor and accessor.get then out = (accessor.get :: any)(out) end
        return out
    end

    function metatable:__newindex(key: any, value: any)
        if environment.Deleting then
            Log.DELETING_STATE:throw(2, environment.Id)
        end
        local accessor = accessorMap[key]
        if PRODUCTION_MODE_ENABLED then
            upsert(data, key, value, getOptions(key, {
                flags = environment.PropertyFlags[key] or {},
                reactive = reactiveMap[key],
                environment = environment,
                type = environment.PropertyTypes[key],
                constructorContext = environment.Context and environment.Context.Constructor or nil,
                set = if accessor then accessor.set else nil,
            }))
            return
        end

        local info = specifierMap[key]
        if not info then
            local super = environment.SuperClass
            if super.object then (super.object :: any)[key] = value; return end
            Log.MISSING_PROP_WRITE:throw(2, key)
        end
        local static, specifier, reactive = info.static, info.specifier, reactiveMap[key]
        if specifier == "public" and not static and not hasFlagsMap[key] then
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
        upsert(ring, key, value, getOptions(key, {
            flags = environment.PropertyFlags[key] or {},
            reactive = reactive,
            environment = environment,
            type = environment.PropertyTypes[key],
            constructorContext = if environment.Context then (environment.Context :: any).Constructor else nil,
            set = if accessor then accessor.set else nil,
        }))
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
            return nil :: any, nil
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