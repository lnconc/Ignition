--!strict
-- Modules/Unyieldable.lua

local function unyieldable<A, R>(fn: (...any) -> ...any, ...: A): (boolean, ...R)
    local thread = coroutine.create(fn)
    local results = {coroutine.resume(thread, ...)}
    local success = results[1]
    
    if not success then
        return false, results[2]
    end

    if coroutine.status(thread) == "suspended" then
        coroutine.close(thread)
        return true, "coroutine suspended"
    end
    return false, table.unpack(results, 2)
end

return unyieldable