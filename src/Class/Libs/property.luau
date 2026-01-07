--!strict
-- Class/Libs/property.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Symbol<T> = Types.Symbol<T>
type Property<V, T, H> = {
    type: T?,
    value: V,
    flags: { Symbol<string> }?,
    get: H?,
    set: (<P>(value: P, this: V) -> P)?,
}
type FinalProperty<V, T, H> = Types.FinalProperty<V, T, nil, H>
type PropertyExposure = Types.PropertyExposure

local IS_SERVER = game:GetService("RunService"):IsServer()

local function property<V, T, H>(options: Property<V, T, H> & { exposure: PropertyExposure }): FinalProperty<V, T, H>?
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
        dummy = nil,
        get = options.get,
        set = options.set,
    }
    
    return result :: any
end

return property