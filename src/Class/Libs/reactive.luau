--!strict
-- Class/Libs/reactive.lua

local fetchInterface = require("../Utility/fetchInterface")

local function reactive(_)
    fetchInterface().flags.AllowReactivity = true
end

return reactive