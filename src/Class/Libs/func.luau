--!strict
-- CLass/Libs/func.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Symbol<T> = Types.Symbol<T>
type FinalProperty<D> = Types.FinalProperty<nil, ForceSingleton<"function">, D>
type PropertyExposure = Types.PropertyExposure
type ForceSingleton<S> = Types.ForceSingleton<S>

type FuncOptions<D> = { exposure: PropertyExposure?, flags: { Symbol<string> }?, dummy: D }

local IS_SERVER = game:GetService("RunService"):IsServer()

local function func<D>(options: FuncOptions<D>): FinalProperty<D>?
    local exposure = options.exposure
    if (exposure and exposure ~= "shared") and
        ((IS_SERVER and exposure ~= "server") or (not IS_SERVER and exposure ~= "client"))
    then
        return nil
    end
    local result = { 
        _signature = Configuration.PROPERTY_SIGNATURE, 
        value = nil, 
        type = "function",
        flags = options.flags or {}, 
        dummy = options.dummy 
    }
    
    return result :: any
end

return func