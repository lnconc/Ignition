--!strict
-- Class/Libs/new.lua

local Types = require("../Types")
local Registry = require("../Utility/Registry")

type Interface = Types.Interface

local function new(nameOrInterface: string | Interface): (...any) -> any
    return function(...: any): any
        local interface: Interface = nameOrInterface :: Interface
        if type(nameOrInterface) == "string" then
            nameOrInterface = Registry.WaitForLink(nameOrInterface)
        end
        local object = interface:instantiate(false, ...)
        return object
    end
end

return new