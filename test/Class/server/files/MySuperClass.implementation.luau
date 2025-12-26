--!nocheck
-- MySuperClass.implementation.lua
local Profiler = require(game.ReplicatedStorage.Ignition.Modules.Profiler)
local Class = require(game.ReplicatedStorage.Ignition.Class)

local import, super, ref, once = Class.import, Class.super, Class.ref, Class.once
if once() then return {} end

local format, random = string.format, math.random

local MySuperClass = import()
MySuperClass(function(self)
    warn(`Creating {tostring(self)}`)
    warn(`{tostring(self)} created`)
end)

return {}