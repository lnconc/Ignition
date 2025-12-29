--!strict
-- CLass/Libs/property.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Property<P> = Types.Property<P>
type FinalProperty<P> = Types.FinalProperty<P>

local IS_SERVER = game:GetService("RunService"):IsServer()

local function property<P>(options: Property<P>): FinalProperty<P>?
    local exposure = options.exposure
    if (exposure and exposure ~= "shared") and
        ((IS_SERVER and exposure ~= "server") or (not IS_SERVER and exposure ~= "client"))
    then
        return nil
    end
    return setmetatable(options, { __metatable = Configuration.PROPERTY_SIGNATURE })
end

return property