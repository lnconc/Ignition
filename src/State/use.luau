--!strict
-- State/use.lua

local is = require("./is")

local function createUse(currentDependencies: any): (value: any) -> any
    local function use(value: any): any
        if not is(value) then return value end
        currentDependencies[value] = true
        return value._DANGEROUS_value
    end
    return use
end

return createUse