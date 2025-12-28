--!strict
-- Class/Private/abstract.lua

local fetchInterface = require("../Utility/fetchInterface")

local function abstract(_)
    fetchInterface().flags.ClassAbstracted = true
end

return abstract