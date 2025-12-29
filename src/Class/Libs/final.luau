--!strict
-- Class/Libs/final.lua

local fetchInterface = require("../Utility/fetchInterface")

local function final(_: any)
    fetchInterface().flags.ClassFinalized = true
end

return final