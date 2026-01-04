--!strict
-- Class/Libs/final.lua

local function final(interface: any): any
    interface.flags.ClassFinalized = true
    return interface
end

return final