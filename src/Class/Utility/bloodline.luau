--!strict
-- Class/Utility/bloodline.lua

local Types = require(script.Parent.Parent.Types)
type Environment = Types.Environment

local function bloodline(childEnv: Environment, superEnv: Environment)
    local childFamily = childEnv.Context.Family
    local parentFamily = superEnv.Context.Family
    for className, inclusionMap in pairs(parentFamily) do
        childFamily[className] = inclusionMap
    end

    local childName = childEnv.Interface.name
    local childMethods = childFamily[childName]
    
    if childMethods then
        for _, ancestorInclusion in pairs(parentFamily) do
            for methodId in pairs(childMethods) do
                ancestorInclusion[methodId] = true
            end
        end
    end
end

return bloodline