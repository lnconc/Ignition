--!strict
-- Class/Libs/new.lua

local Types = require("../Types")

type Interface = Types.Interface

local function new(interface: Interface): (...any) -> any
    return function(...: any): any
        local object = interface:instantiate(false, ...)
        return object
    end
end

return new