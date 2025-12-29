--!strict
-- Class/Utility/is_property.lua

local Types = require("../Types")
local Configuration = require("./Configuration")

type FinalProperty<T> = Types.FinalProperty<T>

local function is_property<T>(property: FinalProperty<T>)
    return type(property) == "table" and getmetatable(property) == Configuration.PROPERTY_SIGNATURE
end

return is_property