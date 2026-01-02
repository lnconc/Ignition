--!strict
-- Class/Libs/abstract.lua

local fetchInterface = require("../Utility/fetchInterface")

local function abstract(interface: any): any
    fetchInterface().flags.ClassAbstracted = true
    return interface
end

return abstract