--!strict
-- Class/Private/final.lua

local fetchInterface = require("../Utility/fetchInterface")

local function final(_)
    fetchInterface().flags.ClassFinalized = true
end

return final