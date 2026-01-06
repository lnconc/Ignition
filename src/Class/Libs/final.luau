--!strict
-- Class/Libs/final.lua
local Log = require("../../Log")

local function final(interface: any): any
    if interface.flags.ClassAbstracted then
        Log.FINAL_TO_ABSTRACT:throw(2, interface.name)
    end
    interface.flags.ClassFinalized = true
    return interface
end

return final