--!strict
-- Class/Libs/abstract.lua

local fetchInterface = require("../Utility/fetchInterface")

local function abstract(_: any)
    fetchInterface().flags.ClassAbstracted = true
end

return abstract