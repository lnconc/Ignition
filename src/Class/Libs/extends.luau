--!strict
-- Class/Libs/extends.lua

local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
local Types = require("../Types")
local Registry = require("../Utility/Registry")

type Interface = Types.Interface
type PropertiesFields = Types.PropertiesFields

local function extends<I>(targetOrSuperInterface: string | I): (...any) -> ...any
    local superInterface: Interface = targetOrSuperInterface :: I
    if type(superInterface) == "string" then
        superInterface = Registry.WaitForLink(targetOrSuperInterface)
    end
    local _, _, env = getCaller(2)
    if not env then
        Log.THREAD_CONTEXT_REQUIRED:throw(2, "extends()")
    end
    
    local interface: Interface = env.interface
    if not interface then
        Log.CLASS_INTERFACE_REQUIRED:throw(2, "extends()")
    end
    
    if interface.superclass then
        Log.ALREADY_INHERITS:throw(2, interface.name, interface.superclass.name)
    elseif (superInterface :: Interface).flags.ClassFinalized then
        Log.INHERIT_FINALIZED:throw(2, superInterface.name)
    elseif (superInterface :: Interface).name == interface.name then
        Log.SELF_INHERITANCE:throw(2, interface.name)
    end
    
    interface.superclass = superInterface
    return function(fields: PropertiesFields): PropertiesFields
        return fields
    end
end

return extends