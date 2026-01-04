--!strict
-- Class/Utility/is_property.lua

local Types = require("../Types")
local Configuration = require("./Configuration")

type FinalProperty<V, T, D> = Types.FinalProperty<V, T, D>

local function is_property<V, T, D>(property: FinalProperty<V, T, D>)
    return type(property) == "table" and property._signature == Configuration.PROPERTY_SIGNATURE
end

return is_property