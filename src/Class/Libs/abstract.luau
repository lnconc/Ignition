--!strict
-- Class/Libs/abstract.lua

local function abstract(interface: any): any
    interface.flags.ClassAbstracted = true
    return interface
end

return abstract