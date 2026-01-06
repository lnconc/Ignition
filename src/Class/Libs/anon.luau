--!strict
-- Class/Libs/anon.lua
local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
local Configuration = require("../Utility/Configuration")
local Types = require("../Types")

type Environment = Types.Environment

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local tracebackCache = setmetatable({}, {__mode = "v"})

local function hashString(str: string): number
    local hash = 5381
    for i = 1, #str do
        local char = string.byte(str, i)
        hash = bit32.bxor((bit32.lshift(hash, 5) + hash), char)
    end
    return hash
end

local anon = setmetatable({
    __cache = tracebackCache,
    delete = function(closure)
        for hash, cache in tracebackCache do
            if cache == closure then
                tracebackCache[hash] = nil
                break
            end
        end
    end
}, {
    __call = function<F>(_, callback: F): F
        if PRODUCTION_MODE_ENABLED then return callback end
        local _a: string, _b: string = debug.info(2, "sl")
        local traceback = _a .. _b
        local hash = hashString(traceback)
        if tracebackCache[hash] then
            return tracebackCache[hash]
        end

        local _, _, env = getCaller(2)
        if not env then
            Log.THREAD_CONTEXT_REQUIRED:throw(2, "anon()")
        end
        local environment: Environment = env.environment
        if not environment then
            Log.CLASS_ENVIRONMENT_REQUIRED:throw(2, "anon()")
        end

        local wrapped = function(...)
            return (callback :: any)(...)
        end
        local id = tostring(wrapped)
        environment.Context.Includes[id] = true
        table.insert(environment.Closures, wrapped)
        tracebackCache[hash] = wrapped
        return wrapped :: F
    end
})

type anon = <F>(callback: F) -> F

return (anon :: any) :: anon