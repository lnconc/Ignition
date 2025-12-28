--!strict
-- Class/Libs/once.lua

local getCaller = require("../../Internal/getCaller")

local function once(): boolean
    local _, _, env = getCaller(2)
    if env.pragma_once then
        return true
    end
    env.pragma_once = true
    return false
end

return once