--!strict
-- Class/Private/extends.lua

local getCaller = require(script.Parent.Parent.Parent.Internal.getCaller)
local Types = require(script.Parent.Parent.Types)
local Registry = require(script.Parent.Parent.Utility.Registry)

type Interface = Types.Interface

local function extends(superName: string): (...any) -> ...any
    local superInterface = Registry.WaitForLink(superName)
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
    elseif superInterface.flags.ClassFinalized then
        error(`Cannot inherit from finalized class '{superName}'`, 2)
    elseif superInterface.name == interface.name then
        error(`Class '{interface.name}' cannot inherit from itself`, 2)
    end
    
    interface.superclass = superInterface
    return function(...)
        return ...
    end
end

return extends