--!strict
-- Class/Private/ref.lua

local getCaller = require("../../Internal/getCaller")
local Configuration = require("../Utility/Configuration")

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local function ref(callback: (...any) -> ()) -- made to bypass hitting cclosures when using stuff like: RunService.Heartbeat:Connect(), event:Connect(), task.spawn, coroutine.wrap
    if PRODUCTION_MODE_ENABLED then return callback end -- no need to wrap
    local _, _, env = getCaller(3) -- 0 (getCaller), 1 (super), 2 (method), 3 (wrapped, which has the environment global); reason why it's 2 is because `getCaller` automatically adjusts itself by adding 1 to `level`
    if not env then
        error("out of bounds (reached cclosures)", 2)
    end
    local environment = env.environment
    if not environment then
        error("cannot find source environment", 2)
    end
    local wrapped = function(...)
        return callback(...)
    end
    local id = tostring(wrapped)
    environment.Context.Refs[id] = true
    -- ensure this is also added to our superclass (if we have)
    local current = environment.SuperClass.environment
    while current do
        current.Context.Refs[id] = true
        current = current.SuperClass.environment
    end
    return wrapped
end

return ref