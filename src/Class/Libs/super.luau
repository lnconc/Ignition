--!strict
-- Class/Libs/super.lua

local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
local Configuration = require("../Utility/Configuration")
local bloodline = require("../Utility/bloodline")
local Types = require("../Types")

type Interface = Types.Interface
type Environment = Types.Environment

local DEVELOPMENT_MODE_ENABLED = not Configuration.PRODUCTION_MODE_ENABLED

local function super(...: any)
    local _, _, callEnv = getCaller(2)
    
    if not callEnv then
        Log.THREAD_CONTEXT_REQUIRED:throw(2, "super()")
    end
    
    local environment: Environment = callEnv.environment
    if not environment then
        Log.CLASS_ENVIRONMENT_REQUIRED:throw(2, "super()")
    end
    
    if environment.SuperClass.object then
        Log.ALREADY_INHERITS:throw(2, environment.Id, environment.SuperClass.environment.Id)
    end
    
    local superClassInterface = environment.Interface.superclass
    if not superClassInterface then
        Log.MISSING_SUPER:throw(2, environment.Interface.name)
    end
    
    local superObject, superEnvironment = (superClassInterface :: Interface):instantiate(true, false, ...)
    environment.SuperClass = { 
        object = superObject, 
        environment = superEnvironment 
    }
    
    if environment.Master then
        superEnvironment.Master = environment.Master
    end

    if DEVELOPMENT_MODE_ENABLED then
        bloodline(environment, superEnvironment)
        local interfaceName = environment.Interface.name
        local family = environment.Context.Family
        
        local inclusion = family[interfaceName] or {}
        inclusion[callEnv.current_context] = true
        family[interfaceName] = inclusion
    end
end

return super