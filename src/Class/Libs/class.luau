--!strict
-- Class/Libs/class.luau

local env = require("../../Internal/env")
local getCaller = require("../../Internal/getCaller")
local Symbol = require("../../Modules/Symbol")
local Types = require("../Types")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")
local encapsulate = require("../Utility/encapsulate")
local getOverloadedFunction = require("../Utility/getOverloadedFunction")
local is_property = require("../Utility/is_property")

type Curry<T> = Types.Curry<T>
type Flags = Types.Flags
type Set<T> = Types.Set<T>
type Map<K, V> = Types.Map<K, V>
type Options = Types.Options
type Interface = Types.Interface
type Properties = Types.Properties
type Function = Types.Function
type BaseObject = Types.BaseObject<Properties>
type Environment = Types.Environment

local find = table.find
local match = string.match
local toString = tostring

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
if not PRODUCTION_MODE_ENABLED then
    warn("class library is on development mode, set FORCE_PRODUCTION_MODE to true to disable")
end

local function buildClassObject(options): (BaseObject, Environment)
    local id = Symbol(`{options.IdentifierName}({string.format("%08X", math.random(0, 0x7FFFFFFF))})`)
    
    local environment: Environment = {
        Id = id,
        Interface = Registry.GetInterface(options.IdentifierName),
        SuperClass = { object = nil, environment = nil },
        Master = nil,
        Context = if PRODUCTION_MODE_ENABLED then {
            Constructor = {},
        } :: any else {
            Includes = {} :: Set<string>,
            Refs = setmetatable({}, { __mode = "k" }) :: Set<string>,
            Friends = {} :: Set<string>,
            Family = {},
            Constructor = {},
        },
        Flags = {
            AllowReactivity = options.AllowReactivity,
        },
        PropertyFlags = {},
        PropertyTypes = {},
        Closures = {},
    }
    
    local object = newproxy(true)
    local metatable = getmetatable(object)
    metatable.__tostring = function()
        return toString(id)
    end
    
    encapsulate(object, metatable, environment, options.PropertyFields)
    return object, environment
end

local function createClassInterface(name: string): (fields: Properties) -> ()
    local script, fn = getCaller(2)
    local headerExt = Configuration.HEADER_EXTENSION
    if not match(script.Name, `%.{headerExt}$`) then
        error(`Class interface '{name}' must be defined in a '.{headerExt}' file (got '{script.Name}')`, 2)
    end
    
    if Registry.InterfaceExists(name) then
        error(`Class interface '{name}' already exists`, 2)
    end
    
    local interface = setmetatable({
        name = name,
        flags = {
            AllowReactivity = false,
            ClassFinalized = false,
            ClassAbstracted = false,
            InheritanceLinked = false,
        } :: Flags,
        constructor = { callback = nil, defined = false },
        superclass = nil,
        closures = {},
        globals = { public = {}, protected = {}, private = {} },
        properties_fields = { public = {}, protected = {}, private = {} },
        
        instantiate = function(self: Interface, fromDerivedClass: boolean, ...: any)
            if self.flags.ClassAbstracted and not fromDerivedClass then
                error(`Cannot instantiate abstract class {self.name}`, 3)
            end
            local options = {
                AllowReactivity = self.flags.AllowReactivity,
                ClassAbstracted = self.flags.ClassAbstracted,
                ClassFinalized = self.flags.ClassFinalized,
                IdentifierName = name,
                PropertyFields = self.properties_fields,
            }
            
            local object, environment = buildClassObject(options)
            local constructorData = self.constructor.callback
            local fn = if type(constructorData) == "table" and constructorData.isOverloaded 
                then getOverloadedFunction(`Constructor<{tostring(object)}>`, constructorData) 
                else constructorData
            fn = fn or function() end
            if fn then
                local wrapper = function(...) 
                    (fn :: Function)(object, ...)
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
                    
                    environment.Context.Constructor[build_context] = true
                    environment.Context.Includes[build_context] = true

                    wrapper(...)
                end
            end
            
            if not fromDerivedClass then -- propagate master and constructors to superclasses
                environment.Master = object
                local current = environment
                while current.SuperClass and current.SuperClass.environment do
                    current.SuperClass.environment.Master = object
                    current.SuperClass.environment.Context.Constructor = environment.Context.Constructor
                    current = current.SuperClass.environment
                end
            end
            
            return object, environment
        end
    }, { __metatable = "This metatable is locked!" })
    
    Registry.FlushTasks(2, interface)
    env.set(fn, { interface = interface })
    return function(fields: Properties)
        local propertyFlags = Configuration.PROPERTY_FLAGS
        
        local function handleVirtuals(specifier: string, key: string)
            local super = interface.superclass
            if not super then return end
            
            local parent_fields = super.properties_fields[specifier]
            local existing = parent_fields[key]
            if existing then
                local is_virtual = false
                if type(existing) == "table" and existing.flags then
                    is_virtual = find(existing.flags, propertyFlags.Virtual) ~= nil
                end
                
                if not is_virtual then
                    error(`Cannot override non-virtual property '{key}' inherited from {super.name}`, 2)
                end
            end
        end
        
        for k, v in pairs(fields) do
            local is_specifier = (k == 'public' or k == 'private' or k == 'protected') 
            local is_field_group = is_specifier and type(v) == "table" and not is_property(v)
            if is_field_group then
                for subKey, subValue in pairs(v :: any) do
                    handleVirtuals(k, subKey)
                    interface.properties_fields[k][subKey] = subValue
                end
            else
                handleVirtuals("public", k)
                interface.properties_fields.public[k] = v
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