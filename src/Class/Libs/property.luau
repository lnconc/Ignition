--!strict
-- Class/Libs/property.lua

local Configuration = require("../Utility/Configuration")

local IS_SERVER = game:GetService("RunService"):IsServer()

local function property(options: any): any?
    local exposure = options.from
    if (exposure and exposure ~= "shared") and
        ((IS_SERVER and exposure ~= "server") or (not IS_SERVER and exposure ~= "client"))
    then
        return nil
    end
    local inferredType = options.type
    if not inferredType then
        if options.value == nil or (options.value ~= nil and type(options.value) == "userdata" and (getmetatable(options.value) :: any) == Configuration.PROPERTY_SIGNATURE) then
            inferredType = "any"
            return
        end
        inferredType = typeof(options.value)
    end
    local result = setmetatable({ 
        value = options.value,
        type = inferredType,
        flags = options.flags or {}, 
        dummy = nil,
        get = options.get,
        set = options.set,
    }, { __metatable = Configuration.PROPERTY_SIGNATURE})
    
    return result
end

return property