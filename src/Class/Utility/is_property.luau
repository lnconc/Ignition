--!strict
-- Class/Utility/is_property.lua

local Types = require("../Types")
local Configuration = require("./Configuration")

type FinalProperty<V, T = string> = Types.FinalProperty<V, T>

local function is_property<V, T>(property: FinalProperty<V, T>)
    return type(property) == "table" and property._signature == Configuration.PROPERTY_SIGNATURE
end

return is_property