--!nocheck
-- Internal/getCaller.lua

type Scriptable = LocalScript | Script | ModuleScript | CoreScript | BaseScript
type Environment = { [string]: any }
type Closure = (...any) -> (...any)

local accessCache = setmetatable({}, {__mode = "k"})

local function callerInternals(fn): ...any
    local env = getfenv(fn)
    return env.script, fn, env
end

local function getCaller(level: number | boolean): (Scriptable, Closure?, Environment)
    local fn
    local origin = debug.traceback(nil, 2)
    if accessCache[origin] then return callerInternals(accessCache[origin]) end
    if type(level) == "boolean" then -- get the top-most stack before we hit c-closure
        local l = 2
        while true do
            local _, _fn, line = pcall(debug.info, l, "fl")
            if not _fn or line == -1 then break end
            fn = _fn
            l += 1
        end
    else
        local _, _fn = pcall(debug.info, level + 2, "f")
        fn = _fn
    end
    
    if fn then
        accessCache[origin] = fn
        return callerInternals(fn)
    end
    return script, nil, nil
end

return getCaller