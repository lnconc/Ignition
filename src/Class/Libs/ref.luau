--!strict
-- Class/Libs/ref.lua

local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
local Configuration = require("../Utility/Configuration")
local Types = require("../Types")

type Environment = Types.Environment

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local function ref<F>(callback: F): F -- made to bypass hitting cclosures when using stuff like: RunService.Heartbeat:Connect(), event:Connect(), task.spawn, coroutine.wrap
    if PRODUCTION_MODE_ENABLED then return callback end -- no need to wrap
    local _, _, env = getCaller(2)
    if not env then
        Log.THREAD_CONTEXT_REQUIRED:throw(2, "ref()")
    end
    local environment: Environment = env.environment
    if not environment then
        Log.CLASS_ENVIRONMENT_REQUIRED:throw(2, "ref()")
    end
    local wrapped = function(...)
        return (callback :: any )(...)
    end
    environment.Context.Refs[wrapped] = true
    -- ensure this is also added to our superclass (if we have)
    local current = environment.SuperClass.environment
    while current do
        current.Context.Refs[wrapped] = true
        current = current.SuperClass.environment
    end
    return wrapped
end

return ref