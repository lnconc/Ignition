--!strict
-- Class/Libs/property.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Symbol<T> = Types.Symbol<T>
type Property<V, T> = {
    type: T?,
    value: V,
    flags: { Symbol<string> } | { [Symbol<string>]: boolean },
}
type FinalProperty<V, T> = Types.FinalProperty<V, T, nil>
type PropertyExposure = Types.PropertyExposure

local IS_SERVER = game:GetService("RunService"):IsServer()

local function property<V, T>(options: Property<V, T> & { exposure: PropertyExposure }): FinalProperty<V, T>?
    local exposure = options.exposure
    if (exposure and exposure ~= "shared") and
        ((IS_SERVER and exposure ~= "server") or (not IS_SERVER and exposure ~= "client"))
    then
        return nil
    end
    local result = { 
        _signature = Configuration.PROPERTY_SIGNATURE, 
        value = options.value,
        type = options.type,
        flags = options.flags or {}, 
        dummy = nil
    }
    
    return result :: any
end

return property