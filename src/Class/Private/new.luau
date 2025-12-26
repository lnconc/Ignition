--!strict
-- Class/Private/new.lua

local Types = require(script.Parent.Parent.Types)
local Registry = require(script.Parent.Parent.Utility.Registry)

type Interface = Types.Interface
type BaseObject<P> = Types.BaseObject<P>
type Properties = Types.Properties

local function new(name: string): (...any) -> any
    local interface = Registry.WaitForLink(name)
    return function(...: any): BaseObject<Properties>
        local object = interface:instantiate(false, ...)
        return object
    end
end

return new