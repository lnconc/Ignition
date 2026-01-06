--!strict
-- CLass/Libs/property.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Property<P> = Types.Property<P>
type PropertyRaw<P> = Types.PropertyRaw<P>

local function property<P>(options: PropertyRaw<P>): Property<P>
    return setmetatable(options, { __metatable = Configuration.PROPERTY_SIGNATURE })
end

return property