--!strict
-- Class/Libs/reactive.lua

local fetchInterface = require("../Utility/fetchInterface")

local function reactive(interface: any): any
    fetchInterface().flags.AllowReactivity = true
    return interface
end

return reactive