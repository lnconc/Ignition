--!strict
-- States/is.lua

local Types = require(script.Parent.Types)

type CanBe<T> = Types.CanBe<T>

local function peek<T>(value: CanBe<T>): T
    return value
end

return peek