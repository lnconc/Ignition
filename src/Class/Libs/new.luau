--!strict
-- Class/Libs/new.lua

local Registry = require("../Utility/Registry")

local function new(nameOrInterface: string | any): (...any) -> any
    if type(nameOrInterface) == "table" then
        local mt = getmetatable(nameOrInterface) :: any
        if mt and mt.fromImport then
            nameOrInterface = mt.interface
        end
    end
    local interface = nameOrInterface
    if type(nameOrInterface) == "string" then
        interface = Registry.WaitForLink(nameOrInterface)
    end
    return function(...: any): any
        local object = interface:instantiate(false, false, ...)
        return object
    end
end

return new