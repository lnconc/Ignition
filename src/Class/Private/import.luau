--!strict
-- Class/Private/import.lua

local getCaller = require(script.Parent.Parent.Parent.Internal.getCaller)
local Types = require(script.Parent.Parent.Types)
local Configuration = require(script.Parent.Parent.Utility.Configuration)
local Registry = require(script.Parent.Parent.Utility.Registry)

local VIRTUAL_FLAG = Configuration.PROPERTY_FLAGS.Virtual

type ReflectedClass<P> = Types.ReflectedClass<P>
type Function = Types.Function
type Expects = Types.Expects
type OverloadRecord = Types.OverloadRecord

local function import<P>(): ReflectedClass<P>
    local callerScript = getCaller(2)
    local className = callerScript.Name:split(".")[1]
    local interface = Registry.WaitForInterface(className)
    
    local function verifyImplementation(key: string, isFunction: boolean)
        local rings = interface.properties_fields
        local found = rings.private[key] or rings.protected[key] or rings.public[key]
        
        if not found then
            error(`Member '{key}' must be defined in the header...`, 3)
        end

        local currentClosure = interface.closures[key]
        if isFunction and currentClosure and (type(currentClosure) ~= "table" or not currentClosure.isOverloaded) then
            local isVirtual = interface.virtuals[key]
            if isVirtual == nil then
                local flags = if type(found) == "table" then found.flags else nil
                isVirtual = if type(flags) == "table" then table.find(flags, VIRTUAL_FLAG) ~= nil else flags[VIRTUAL_FLAG]
                interface.virtuals[key] = isVirtual
            end

            if not isVirtual then
                error(`Cannot override non-virtual member '{key}' in class '{interface.name}'`, 3)
            end
        end
        return found
    end

    local imported = setmetatable({}, {
        __call = function(_, targetOrSignature: Function | Expects, _signature: Expects?)
            if type(targetOrSignature) == "function" then
                if type(_signature) == "table" and #_signature > 0 then
                    local current = interface.constructor.callback
                    if current then
                        interface.constructor.callback = {
                            isOverloaded = true,
                            overloads = {},
                            fallback = if type(current) == "function" then current else nil,
                        }
                        current = interface.constructor.callback
                    end
                    table.insert((current :: OverloadRecord).overloads, {
                        callback = targetOrSignature,
                        expects = _signature,
                    })
                else
                    if interface.constructor.defined then
                        error(`Constructor for '{interface.name}' already defined.`, 2)
                    end
                    interface.constructor.callback = targetOrSignature
                end
                interface.constructor.defined = true
                return nil :: any
            elseif type(targetOrSignature) == "table" and #targetOrSignature > 0 then
                return function(memberName: string)
                    verifyImplementation(memberName, true)
                    return function(implementation: Function)
                        local current = interface.closures[memberName]
                        if not current or type(current) == "function" then
                            interface.closures[memberName] = {
                                overloads = {},
                                isOverloaded = true,
                                fallback = if type(current) == "function" then current else nil,
                            }
                            current = interface.closures[memberName]
                        end
                        table.insert((current :: OverloadRecord).overloads, {
                            callback = implementation,
                            expects = targetOrSignature :: Expects
                        })
                    end
                end
            end
            error("Invalid import call. Expected a constructor or non-empty type signature.", 2)
        end,
        __newindex = function(_, key, value)
            local isFn = type(value) == "function"
            local found = verifyImplementation(key, isFn)

            if isFn and found then
                local current = interface.closures[key]
                if type(current) == "table" and current.isOverloaded then
                    if current.fallback then
                        error(`Default/fallback implementation for '{key}' is already defined in '{interface.name}'.`, 2)
                    end
                    current.fallback = value
                else
                    interface.closures[key] = value
                end
            end
        end,
        __index = function(_)
            error(`'{interface.name}' implementation is write-only. Use the header for type info.`, 2)
        end
    })

    return imported
end

return import