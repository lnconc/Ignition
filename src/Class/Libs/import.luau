--!strict
-- Class/Libs/import.lua

local getCaller = require("../../Internal/getCaller")
local Types = require("../Types")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")

type AnyFunction = Types.AnyFunction
type Expects = Types.Expects
type OverloadRecord = Types.OverloadRecord

local VIRTUAL_FLAG = Configuration.PROPERTY_FLAGS.Virtual

local function import(): any
    local callerScript = getCaller(2)
    local className = callerScript.Name:split(".")[1]
    local interface = Registry.WaitForInterface(className)
    
    local function verifyImplementation(key: string, isFunction: boolean)
        local rings = interface.properties
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
        __call = function(_, targetOrSignature: AnyFunction | Expects)
            if type(targetOrSignature) == "function" then
                if interface.constructor.defined then
                    error(`Constructor for '{interface.name}' already defined.`, 2)
                end
                interface.constructor.callback = targetOrSignature :: any
                return nil :: any
            elseif type(targetOrSignature) == "table" and #targetOrSignature > 0 then
                return function(memberNameOrConstructor: string | AnyFunction)
                    if type(memberNameOrConstructor) == "function" then
                        local current = interface.constructor.callback
                        if current then
                            interface.constructor.callback = {
                                isOverloaded = true,
                                overloads = {},
                                fallback = if type(current) == "function" then current else nil :: any,
                            }
                            current = interface.constructor.callback
                        end
                        table.insert((current :: OverloadRecord).overloads, {
                            callback = memberNameOrConstructor,
                            expects = targetOrSignature,
                        })
                        return nil :: any
                    else
                        verifyImplementation(memberNameOrConstructor, true)
                        return function(implementation: AnyFunction)
                            local current = interface.closures[memberNameOrConstructor]
                            if not current or type(current) == "function" then
                                interface.closures[memberNameOrConstructor] = {
                                    overloads = {},
                                    isOverloaded = true,
                                    fallback = if type(current) == "function" then current else nil :: any,
                                }
                                current = interface.closures[memberNameOrConstructor]
                            end
                            table.insert((current :: OverloadRecord).overloads, {
                                callback = implementation,
                                expects = targetOrSignature :: Expects
                            })
                        end
                    end
                end
            end
            error("Invalid import call. Expected a constructor or non-empty type signature.", 2)
        end,
        __newindex = function(_, key, value: AnyFunction | any)
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