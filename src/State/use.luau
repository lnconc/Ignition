--!strict
-- State/use.lua

local Types = require("./Types")
local is = require("./is")

type GraphObject<T> = Types.GraphObject<T>
type GraphDependencies = Types.GraphDependencies

local function createUse<T>(currentDependencies: GraphDependencies): (value: GraphObject<T>) -> T
    local function use<A, B>(value: GraphObject<A>): B
        if not is(value) then return value end
        currentDependencies[value] = true
        return (value :: any)._DANGEROUS_value
    end
    return use
end

return createUse