--!strict
-- Class/Libs/import.lua

local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
local Types = require("../Types")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")

type AnyFunction = Types.AnyFunction
type Expects = Types.Expects
type OverloadRecord = Types.OverloadRecord
type Interface = Types.Interface

local VIRTUAL_FLAG = Configuration.PROPERTY_FLAGS.Virtual

local function import(_interface: Interface?): any
    local interface: Interface = _interface :: Interface
    if not _interface then
        local callerScript = getCaller(2)
        interface = Registry.WaitForInterface(callerScript.Name:split(".")[1])
    end

    local function verifyImplementation(key: string, isFunction: boolean)
        local rings = interface.properties
        local found = rings.private[key] or rings.protected[key] or rings.public[key]
        
        if not found then
            Log.CANNOT_FIND_IMPLEMENTATION:throw(2, key)
        end

        local currentClosure = interface.closures[key]
        if isFunction and currentClosure and (type(currentClosure) ~= "table" or not currentClosure.isOverloaded) then
            local isVirtual = interface.virtuals[key]
            if isVirtual == nil then
                local flags = if type(found) == "table" then found.flags else nil
                isVirtual = flags and flags[VIRTUAL_FLAG] ~= nil
                interface.virtuals[key] = isVirtual
            end

            if not isVirtual then
                Log.OVERRIDE_NON_VIRTUAL:throw(2, key, interface.name)
            end
        end
        return found
    end

    local imported = setmetatable({}, {
        __call = function(_, targetOrSignature: AnyFunction | Expects)
            if type(targetOrSignature) == "function" then
                if interface.constructor.defined then
                    Log.CONSTRUCTOR_EXISTS:throw(2, interface.name)
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
            Log.INVALID_IMPORT_CALL:throw(2)
            return nil
        end,
        __newindex = function(_, key, value: AnyFunction | any)
            local isFn = type(value) == "function"
            local found = verifyImplementation(key, isFn)

            if isFn and found then
                local current = interface.closures[key]
                if type(current) == "table" and current.isOverloaded then
                    if current.fallback then
                        Log.FALLBACK_EXISTS:throw(2, key, interface.name)
                    end
                    current.fallback = value
                else
                    interface.closures[key] = value
                end
            end
        end,
        __index = function(_, key: string): any
            if key == "__complete__" then
                return function()
                    return setmetatable({}, {
                        __index = function(_, k: string)
                            local val = interface.staticproperties.public[k]
                            if val == nil then
                                Log.MISSING_STATIC_INDEX:throw(2, k, interface.name)
                            end
                            return val
                        end,
                        __newindex = function(_, k: string, v: any)
                            local val = interface.staticproperties.public[k]
                            if val == nil then
                                Log.MISSING_STATIC_WRITE:throw(2, k, interface.name)
                            end
                            interface.staticproperties.public[k] = if v == nil then Configuration.PLACEHOLDER else v
                        end,
                        __metatable = {
                            interface = interface,
                            fromImport = true,
                        },
                        __tostring = function() return `StaticClass<{interface.name}>` end
                    })
                end
            end
            Log.WRITE_ONLY_IMPL:throw(2, interface.name)
            return nil
        end
    })

    return imported
end

return import