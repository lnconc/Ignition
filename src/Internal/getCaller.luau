--!strict
-- Internal/getCaller.lua

local Types = require("./Types")
local env = require("./env")
local resolvePath = require("./resolvePath")

type Scriptable = Types.Scriptable
type FunctionEnvironment = Types.FunctionEnvironment
type Function = Types.Function

local accessCache = setmetatable({}, {__mode = "k"})
local debugInfo = debug.info :: any

local function callerInternals(fn: any): ...any
    local env = env.get(fn)
    local script = resolvePath(debugInfo(fn, "s"))
    return script, fn, env
end

local function getCaller(level: number | boolean): (Scriptable, Function, FunctionEnvironment)
    local fn
    local origin = debug.traceback(nil, 2)
    if accessCache[origin] then return callerInternals(accessCache[origin]) end
    if type(level) == "boolean" then -- get the top-most stack before we hit c-closure
        local l = 2
        while true do
            local _fn, line = debug.info(l, "fl")
            if not _fn or line == -1 then break end
            fn = _fn
            l += 1
        end
    else
        fn = debug.info(level + 2, "f")
    end
    
    if fn then
        accessCache[origin] = fn
        return callerInternals(fn)
    end
    return script, nil :: any, nil :: any
end

return getCaller