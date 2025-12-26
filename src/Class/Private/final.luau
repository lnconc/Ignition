--!strict
-- Class/Private/final.lua

local Registry = require(script.Parent.Parent.Utility.Registry)

local function final(_)
    local thread = coroutine.running()
    Registry.UpsertTask(thread, true)
    local interface = coroutine.yield()
    interface.flags.ClassFinalized = true
end

return final