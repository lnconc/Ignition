--!strict
-- Class/Utility/is_property.lua

local Configuration = require("./Configuration")

local function is_property<P>(property: any)
    return type(property) == "table" and getmetatable(property) == Configuration.PROPERTY_SIGNATURE
end

return is_property