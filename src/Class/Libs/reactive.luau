--!strict
-- Class/Libs/reactive.lua

local function reactive(interface: any): any
    interface.flags.AllowReactivity = true
    return interface
end

return reactive