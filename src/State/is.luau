--!strict
-- States/is.lua

local Value = require(script.Parent.Value)

local ValueMetatable = getmetatable(Value.new(nil))

local function is(object: any): boolean
    return type(object) == "table" and getmetatable(object) == ValueMetatable
end

return is 