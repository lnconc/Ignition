--!strict
-- Class/Private/reactive.lua

local Registry = require(script.Parent.Parent.Utility.Registry)

local function reactive(_) -- in reality, we don't need parameters here, but it's just for the clean syntax
    local thread = coroutine.running()
    Registry.UpsertTask(thread, true)
    local interface = coroutine.yield()
    interface.flags.AllowReactivity = true
end

return reactive