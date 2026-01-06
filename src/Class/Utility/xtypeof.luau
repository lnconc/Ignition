--!strict
-- Class/Utility/xtypeof.luau

local Registry = require("./Registry")

local function xtypeof(x: any): string
    local t = typeof(x)
    if t == "userdata" and tostring(x):find("Symbol") then
        return "symbol"
    end

    if t == "table" then
        if Registry.HasObject(x) then
            return "ignitionclass"
        elseif Registry.HasInterface(x) then
            return "ignitioninterface"
        end

        local success, result = pcall(function()
            if type(x.andThen) == "function" then return "promise" end
            if type(x.Connect) == "function" and type(x.Fire) == "function" then return "signal" end
            if type(x.Disconnect) == "function" then return "connection" end
            return (nil :: any) :: string
        end)
        
        if success and result then return result end
        if getmetatable(x) ~= nil then
            return "metatable"
        end
    end
    return t
end

return xtypeof