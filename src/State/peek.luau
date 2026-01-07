--!strict
-- States/is.lua

local Types = require("./Types")
local is = require("./is")

type CanBe<T> = Types.CanBe<T>

local function peek<T>(value: CanBe<T>): T
    return if is(value) then (value :: any)._DANGEROUS_value else value
end

return peek