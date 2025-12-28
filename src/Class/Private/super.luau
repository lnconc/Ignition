--!strict
-- Class/Private/super.lua

local getCaller = require("../../Internal/getCaller")
local Configuration = require("../Utility/Configuration")
local bloodline = require("../Utility/bloodline")

local DEVELOPMENT_MODE_ENABLED = not Configuration.PRODUCTION_MODE_ENABLED

local traceback = debug.traceback

local function super(...: any)
    local _, _, callEnv = getCaller(3)
    
    if not callEnv then
        error("'super' must be called within a class constructor", 2)
    end
    
    local environment = callEnv.environment
    if not environment then
        error("Could not resolve source environment for 'super' call", 2)
    end
    
    if environment.SuperClass.object then
        warn(`{environment.Id} already has an initialized superclass. Skipping.\n{traceback(nil, 1)}`)
        return
    end
    
    local superClassInterface = environment.Interface.superclass
    if not superClassInterface then
        error(`Class '{environment.Interface.name}' has no superclass defined. Did you forget to use 'extends'?`, 2)
    end
    
    local superObject, superEnvironment = superClassInterface:instantiate(true, ...)
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