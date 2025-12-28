--!strict
-- Ignition.lua

local Class = require("@self/Class")
local Configuration = require("@self/Configuration")
local Profiler = require("@self/Modules/Profiler")
local Promise = require("@self/Modules/Promise")
local Ser = require("@self/Modules/Ser")
local Signal = require("@self/Modules/Signal")
local Symbol = require("@self/Modules/Symbol")
local Unyieldable = require("@self/Modules/Unyieldable")
local Observe = require("@self/State/Observe")
local Property = require("@self/State/Property")
local Value = require("@self/State/Value")

local function loadSolutions(root: Instance, fromSolutions: boolean?)
    for _, item in root:GetChildren() do
        if Configuration.EXCLUDES[item.Name:lower():gsub("%s+", "")] then continue end
        if item:IsA("Folder") then
            if not fromSolutions then
                fromSolutions = item.Name:find(Configuration.SOLUTIONS_KEY) ~= nil
            end
            if fromSolutions then
                for _, module in item:GetChildren() do
                    if module:IsA("ModuleScript") then
                        task.spawn(function()
                            local success, err = pcall(require, module)
                            if not success then
                                warn(`Failed to load {module:GetFullName()}\n\n[Linker Error]:\n{err}`)
                            end
                        end)
                    end
                end
            end
            loadSolutions(item, fromSolutions)
        end
    end
end

loadSolutions(Configuration.ROOT, false)
loadSolutions(Configuration.SHARED_ROOT, false)

return {
    VERSION = Configuration.VERSION,
    Class = Class,
    Promise = Promise,
    Profiler = Profiler,
    Signal = Signal,
    Value = Value,
    Ser = Ser,
    Property = Property,
    Symbol = Symbol,
    Observe = Observe,
    Unyieldable = Unyieldable,
}