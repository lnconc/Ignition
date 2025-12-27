--!strict
-- Class/Utility/fetchInterface.lua

local Types = require(script.Parent.Parent.Types)
local Registry = require(script.Parent.Registry)

type Interface = Types.Interface

local function fetchInterface(): Interface
    local thread = coroutine.running()
    Registry.UpsertTask(thread, true)
    return coroutine.yield()
end

return fetchInterface