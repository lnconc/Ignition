--!strict
-- States/is.lua

local is = require("./is")

local function peek(value: any): any
    return if is(value) then (value :: any)._DANGEROUS_value else value
end

return peek