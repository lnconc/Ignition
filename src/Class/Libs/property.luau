--!strict
-- Class/Libs/property.lua

local Configuration = require("../Utility/Configuration")

local IS_SERVER = game:GetService("RunService"):IsServer()

local function property(options: any): any?
    local from = options.from
    if (from and from ~= "shared") and
        ((IS_SERVER and from ~= "server") or (not IS_SERVER and from ~= "client"))
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
        effect = options.effect,
        dependencies = options.dependencies
    }, { __metatable = Configuration.PROPERTY_SIGNATURE})
    
    return result
end

return property