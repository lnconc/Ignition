--!strict
-- Class/Private/reactive.lua

local fetchInterface = require(script.Parent.Parent.Utility.fetchInterface)

local function reactive(_)
    fetchInterface().flags.AllowReactivity = true
end

return reactive