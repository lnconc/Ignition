--!strict
-- CLass/Libs/prop.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Property<P> = Types.Property<P>
type PropertyRaw<P> = Types.PropertyRaw<P>

local IS_SERVER = game:GetService("RunService"):IsServer()

local function prop<P>(options: PropertyRaw<P>): Property<P>?
    local exposure = options.exposure
    if (exposure and exposure ~= "shared") and
        ((IS_SERVER and exposure ~= "server") or (not IS_SERVER and exposure ~= "client"))
    then
        return nil
    end
    return setmetatable(options, { __metatable = Configuration.PROPERTY_SIGNATURE })
end

return prop