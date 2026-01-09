--!strict
-- States/evaluate.lua

local function evaluate(self: any, latestDependencies: any, oldDependencies: any)
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