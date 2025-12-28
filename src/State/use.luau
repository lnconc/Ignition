--!strict
-- State/use.lua

local Types = require("./Types")
local is = require("./is")

type GraphObjectInternal<T> = Types.GraphObjectInternal<T>
type GraphDependencies = Types.GraphDependencies

local function createUse<T>(currentDependencies: any): (value: GraphObjectInternal<T>) -> T
    local function use<A, B>(value: GraphObjectInternal<A>): B
        if not is(value) then return value end
        (currentDependencies :: { [any]: boolean })[value] = true
        return (value :: any)._DANGEROUS_value
    end
    return use
end

return createUse