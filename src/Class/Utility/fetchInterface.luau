--!strict
-- Class/Utility/fetchInterface.lua

local Types = require("../Types")
local Registry = require("./Registry")

type Interface = Types.Interface

local function fetchInterface(): Interface
    local thread = coroutine.running()
    Registry.UpsertTask(thread, true)
    return coroutine.yield()
end

return fetchInterface