--!strict
-- Class/Libs/class.luau

local env = require("../../Internal/env")
local getCaller = require("../../Internal/getCaller")
local Symbol = require("../Utility/Symbol")
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
type FinalProperty<T> = Types.FinalProperty<T>
type OverloadFunction = Types.OverloadFunction
type Symbol<T> = Types.Symbol<T>

local find = table.find
local match = string.match
local toString = tostring

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
if not PRODUCTION_MODE_ENABLED then
    warn("class library is on development mode, set FORCE_PRODUCTION_MODE to true to disable")
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
            Refs = setmetatable({} :: { [string]: any }, { __mode = "k" }),
            Friends = {},
            Family = {},
            Constructor = "",
        },
        PropertyFlags = {},
        PropertyTypes = {},
        Closures = {},
    }
    
    for _, field in pairs(interface.properties) do
        for key, property in pairs(field :: { [string]: any }) do
            environment.PropertyTypes[key] = (property :: FinalProperty<any>).type
            local flags = (property :: FinalProperty<any>).flags
            if flags then
                environment.PropertyFlags[key] = flags :: { [Symbol<string>]: boolean }
            end
        end
    end

    local object = newproxy(true)
    local metatable = getmetatable(object)
    metatable.__tostring = function()
        return toString(id)
    end
    
    encapsulate(object, metatable, environment, interface.properties)
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
        instantiate = function(self: any, fromDerivedClass: boolean, ...: any): (any, any)
            if self.flags.ClassAbstracted and not fromDerivedClass then
                error(`Cannot instantiate abstract class {self.name}`, 3)
            end
            
            local object, environment = buildClassObject(name, self)
            local constructorData: OverloadRecord = self.constructor.callback
            local fn: OverloadFunction = if type(constructorData) == "table" and constructorData.isOverloaded 
                then getOverloadedFunction(`Constructor<{tostring(object)}>`, constructorData) 
                else constructorData
            fn = fn or function() end
            if fn then
                local wrapper = function(...) 
                    (fn :: (...any) -> ())(object, ...)
                end
                
                local build_context = toString(wrapper)
                if PRODUCTION_MODE_ENABLED then
                    env.set(wrapper, { environment = environment })
                    wrapper(object, ...)
                else
                    env.set(wrapper, { environment = environment, current_context = build_context })
                    local family = environment.Context.Family[name] or {}
                    family[build_context] = true
                    environment.Context.Family[name] = family
                    
                    environment.Context.Constructor = build_context
                    environment.Context.Includes[build_context] = true

                    wrapper(...)
                end
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

local function createClassInterface(name: string): (fields: PropertiesFields) -> ()
    local script, fn = getCaller(2)
    local headerExt = Configuration.HEADER_EXTENSION
    if not match(script.Name, `%.{headerExt}$`) then
        error(`Class interface '{name}' must be defined in a '.{headerExt}' file (got '{script.Name}')`, 2)
    end
    
    if Registry.InterfaceExists(name) then
        error(`Class interface '{name}' already exists`, 2)
    end
    
    local interface: Interface = createInterface(name)
    Registry.FlushTasks(2, interface)
    env.set(fn, { interface = interface })
    return function(fields: PropertiesFields)
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
                    error(`Cannot override non-virtual property '{key}' inherited from {super.name}`, 2)
                end
            end
        end

        local function normalizeProperty(property: FinalProperty<any>): FinalProperty<any>
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
                    if not subKey or not subValue then continue end
                    handleVirtuals(k, subKey);
                    interface.properties[k][subKey] = normalizeProperty(subValue)
                end
            else
                handleVirtuals("public", k)
                interface.properties.public[k] = normalizeProperty(v :: FinalProperty<any>)
            end
        end
        
        interface.flags.InheritanceLinked = true
        if not Registry.InterfaceExists(name) then
            Registry.SaveInterface(interface :: any, name)
        end
        Registry.SignalLink(name, interface :: any)
    end
end

return createClassInterface