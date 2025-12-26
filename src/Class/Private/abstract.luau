--!strict
-- Class/Private/abstract.lua

local Registry = require(script.Parent.Parent.Utility.Registry)

local function abstract(_) -- in reality, we don't need parameters here, but it's just for the clean syntax
    local thread = coroutine.running()
    Registry.UpsertTask(thread, true)
    local interface = coroutine.yield()
    interface.flags.ClassAbstracted = true
end

return abstract