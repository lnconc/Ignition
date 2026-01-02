--!strict
-- Class/Libs/extends.lua

local getCaller = require("../../Internal/getCaller")
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
        error("Extension must be called from a Luau thread context", 2)
    end
    
    local interface: Interface = env.interface
    if not interface then
        error("'extends' must be called within a class header definition", 2)
    end
    
    if interface.superclass then
        error(`'{interface.name}' already inherits from '{interface.superclass.name}'`, 2)
    elseif (superInterface :: Interface).flags.ClassFinalized then
        error(`Cannot inherit from finalized class '{(superInterface :: Interface).name}'`, 2)
    elseif (superInterface :: Interface).name == interface.name then
        error(`Class '{interface.name}' cannot inherit from itself`, 2)
    end
    
    interface.superclass = superInterface
    return function(fields: PropertiesFields): PropertiesFields
        return fields
    end
end

return extends