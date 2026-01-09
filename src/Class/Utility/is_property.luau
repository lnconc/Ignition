--!strict
-- Class/Utility/is_property.lua

local Configuration = require("./Configuration")

local function is_property(property: any)
    return type(property) == "table" and property._signature == Configuration.PROPERTY_SIGNATURE
end

return is_property