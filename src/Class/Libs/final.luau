--!strict
-- Class/Libs/final.lua

local fetchInterface = require("../Utility/fetchInterface")

local function final(interface: any): any
    fetchInterface().flags.ClassFinalized = true
    return interface
end

return final