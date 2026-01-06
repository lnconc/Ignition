--!strict
-- Class/Libs/new.lua

local Types = require("../Types")
local Registry = require("../Utility/Registry")

type Interface = Types.Interface

local function new(nameOrInterface: string | Interface | any): (...any) -> any
    return function(...: any): any
        if type(nameOrInterface) == "table" then
            local mt = getmetatable(nameOrInterface)
            if mt and mt.fromImport then
                nameOrInterface = mt.interface
            end
        end
        local interface: Interface = nameOrInterface :: Interface
        if type(nameOrInterface) == "string" then
            interface = Registry.WaitForLink(nameOrInterface)
        end
        local object = interface:instantiate(false, false, ...)
        return object
    end
end

return new