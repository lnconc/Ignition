--!strict
-- Class/Libs/new.lua

local Types = require("../Types")
local Registry = require("../Utility/Registry")

type Interface = Types.Interface
type GetClassObject<P, A> = Types.GetClassObject<P, A>

local function new(name: string): (...any) -> any
    local interface = Registry.WaitForLink(name)
    type PropertiesField = typeof(interface.properties)

    return function(...: any): any
        local object = interface:instantiate(false, ...)
        return object
    end
end

return new