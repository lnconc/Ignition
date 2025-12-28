--!strict
-- State/use.lua

local Types = require("./Types")
local is = require("./is")

type ValueFull<T> = Types.ValueFull<T>
type GraphDependencies = Types.GraphDependencies

local function createUse<T>(currentDependencies: GraphDependencies): (value: ValueFull<T>) -> T
    local function use<A, B>(value: ValueFull<A>): B
        if not is(value) then return value end
        (currentDependencies :: { [any]: boolean })[value] = true
        return value._DANGEROUS_value
    end
    return use
end

return createUse