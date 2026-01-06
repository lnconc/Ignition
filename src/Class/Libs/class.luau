--!strict
-- Class/Libs/class.luau

local env = require("../../Internal/env")
local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
local Symbol = require("../../Symbol")
local Types = require("../Types")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")
local encapsulate = require("../Utility/encapsulate")
local getOverloadedFunction = require("../Utility/getOverloadedFunction")
local is_property = require("../Utility/is_property")

type Environment = Types.Environment
type Interface = Types.Interface
type GetClassObject<P, A> = Types.GetClassObject<P, A>
type PropertiesFields = Types.PropertiesFields
type AnyFunction = Types.AnyFunction
type OverloadRecord = Types.OverloadRecord
type FinalProperty = Types.FinalProperty<any, "any", any>
type OverloadFunction = Types.OverloadFunction
type Symbol<T> = Types.Symbol<T>

local find = table.find
local match = string.match
local toString = tostring

local PLACEHOLDER = Configuration.PLACEHOLDER
local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
if not PRODUCTION_MODE_ENABLED then
    Log.RAISE_DEV_MODE:warn()
end

local function buildClassObject(name: string, interface: Interface): (any, Environment)
    local id = Symbol(`{name}({string.format("%08X", math.random(0, 0x7FFFFFFF))})`)
    
    local environment: Environment = {
        Id = id,
        Interface = interface,
        SuperClass = { object = nil, environment = nil },
        Master = nil,
        Context = if PRODUCTION_MODE_ENABLED then nil :: any else {
            Includes = {},
            Refs = setmetatable({} :: { [typeof(function() end)]: any }, { __mode = "k" }),
            Friends = {},
            Family = {},
            Constructor = "",
        },
        PropertyFlags = {},
        PropertyTypes = {},
        Closures = {},
        Deleting = false,
    }
    
    for _, field in pairs(interface.properties) do
        for key, property in pairs(field :: { [string]: any }) do
            local isprop = is_property(property)
            if isprop then
                environment.PropertyTypes[key] = (property :: FinalProperty).type
                local flags = (property :: FinalProperty).flags
                if flags then
                    environment.PropertyFlags[key] = flags :: { [Symbol<string>]: boolean }
                end
            else
                environment.PropertyTypes[key] = typeof(property)
            end
        end
    end

    local object = newproxy(true)
    local metatable = getmetatable(object)
    metatable.__tostring = function()
        return toString(id)
    end
    environment.Metatable = metatable
    
    encapsulate(object, metatable, environment)
    return object, environment
end

local function createInterface(name: string): Interface
    local interface = setmetatable({
        name = name,
        flags = {
            AllowReactivity = false,
            ClassFinalized = false,
            ClassAbstracted = false,
            InheritanceLinked = false,
        },
        constructor = { 
            callback = nil :: OverloadFunction?, 
            defined = false 
        },
        superclass = nil :: Interface?,
        closures = {} :: { [string]: OverloadFunction? },
        staticproperties = { public = {}, protected = {}, private = {} },
        properties = { public = {}, protected = {}, private = {} },
        virtuals = {},
        instantiate = function(self: any, fromDerivedClass: boolean, fromInit: boolean, ...: any): (any, any)
            if self.flags.ClassAbstracted and not fromDerivedClass then
                Log.CLASS_ABSTRACTED:throw(2, name)
            end
            
            local object, environment = buildClassObject(name, self)
            Registry.SaveEnvironment(object, environment)
            if fromInit then return object end
            local constructorData: OverloadRecord = self.constructor.callback
            local fn: OverloadFunction = if type(constructorData) == "table" and constructorData.isOverloaded 
                then getOverloadedFunction(`Constructor<{tostring(object)}>`, constructorData) 
                else constructorData
            if fn then
                local wrapper = function(...)
                    (fn :: any)(...)
                end
                
                local build_context = toString(wrapper)
                if PRODUCTION_MODE_ENABLED then
                    env.set(wrapper :: any, { environment = environment })
                else
                    env.set(wrapper :: any, { environment = environment, current_context = build_context })
                    local family = environment.Context.Family[name] or {}
                    family[build_context] = true
                    environment.Context.Family[name] = family
                    
                    environment.Context.Constructor = build_context
                    environment.Context.Includes[build_context] = true
                    table.insert(environment.Closures, wrapper)
                end
                wrapper(object, ...)
            end
            if not fromDerivedClass then
                environment.Master = object
                local current = environment
                while current.SuperClass and current.SuperClass.environment do
                    current.SuperClass.environment.Master = object
                    current = current.SuperClass.environment
                end
            end
            return object, environment
        end
    }, { __metatable = "This metatable is locked!" })
    return interface :: Interface
end

local function createClassInterface(name: string): <I>(fields: PropertiesFields & I) -> I
    local script, fn = getCaller(1)
    local headerExt = Configuration.HEADER_EXTENSION
    if not match(script.Name, `{headerExt}$`) then
        Log.WRONG_FILE_EXT:throw(2, name, headerExt, script.Name)
    end
    
    if Registry.InterfaceExists(name) then
        Log.CLASS_EXISTS:throw(2, name)
    end
    
    local interface: Interface = createInterface(name)
    env.set(fn, { interface = interface })
    return function<I>(fields: PropertiesFields & I): I
        local propertyFlags = Configuration.PROPERTY_FLAGS
        local function handleVirtuals(specifier: string, key: string)
            local super = interface.superclass
            if not super then return end
            
            local parent_fields = super.properties[specifier]
            local existing: any = parent_fields[key]
            if existing then
                local is_virtual = false
                if type(existing) == "table" and existing.flags then
                    is_virtual = find(existing.flags :: {any}, propertyFlags.Virtual) ~= nil
                end
                
                if not is_virtual then
                    Log.OVERRIDE_NON_VIRTUAL:throw(2, key, super.name)
                end
            end
        end

        local function normalizeProperty(property: FinalProperty): FinalProperty
            if is_property(property) then
                local flags = property.flags
                if flags then
                    local map: { [Symbol<string>]: boolean } = {}
                    for _, value in ipairs(flags :: { Symbol<string> }) do
                        map[value] = true
                    end
                    property.flags = map
                end
            end
            return property
        end
        
        for k, v in pairs(fields) do
            local is_specifier = (k == 'public' or k == 'private' or k == 'protected') 
            local is_field_group = is_specifier and type(v) == "table" and not is_property(v)
            if is_field_group then
                for subKey, subValue in pairs(v :: { [string]: any }) do
                    subValue = if subValue == nil then PLACEHOLDER else subValue
                    if not subKey then continue end
                    handleVirtuals(k, subKey);
                    interface.properties[k][subKey] = normalizeProperty(subValue)
                end
            else
                handleVirtuals("public", k)
                interface.properties.public[k] = normalizeProperty(v :: FinalProperty)
            end
        end
        
        interface.flags.InheritanceLinked = true
        if not Registry.InterfaceExists(name) then
            Registry.SaveInterface(interface :: any, name)
        end
        Registry.SignalLink(name, interface :: any)

        return (interface :: any) :: I
    end
end

return createClassInterface