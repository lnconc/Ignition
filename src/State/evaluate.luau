--!strict
-- States/evaluate.lua

local Types = require("./Types")
type GraphDependencies = Types.GraphDependencies
type GraphObject<T> = Types.GraphObject<T>

local function evaluate(self: GraphObject<any>, latestDependencies: GraphDependencies, oldDependencies: GraphDependencies)
    for dep in pairs(latestDependencies) do
        dep._dependencies[self] = true
    end
    for dep in pairs(oldDependencies) do
        if not latestDependencies[dep] then
            dep._dependencies[self] = nil
        end
    end
end

return evaluate