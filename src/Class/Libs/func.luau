--!strict
-- Class/Libs/func.lua

local Configuration = require("../Utility/Configuration")

local IS_SERVER = game:GetService("RunService"):IsServer()

local function func(options: any): any?
    local exposure = options.from
    if (exposure and exposure ~= "shared") and
        ((IS_SERVER and exposure ~= "server") or (not IS_SERVER and exposure ~= "client"))
    then
        return nil
    end
    local result = setmetatable({ 
        value = nil, 
        type = "function",
        flags = options.flags or {}, 
        dummy = options.dummy,
        get = nil,
        set = nil,
    }, { __metatable = Configuration.PROPERTY_SIGNATURE})
    
    return result
end

return func