--!strict
-- Class/Libs/abstract.lua
local Log = require("../../Log")

local function abstract(interface: any): any
    if interface.flags.ClassFinalized then
        Log.ABSTRACT_TO_FINAL:throw(2, interface.name)
    end
    interface.flags.ClassAbstracted = true
    return interface
end

return abstract