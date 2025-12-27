--!strict
-- Ignition.lua

local Class = require(script.Class)
local Configuration = require(script.Configuration)
local Profiler = require(script.Modules.Profiler)
local Promise = require(script.Modules.Promise)
local Ser = require(script.Modules.Ser)
local Signal = require(script.Modules.Signal)
local Symbol = require(script.Modules.Symbol)
local Unyieldable = require(script.Modules.Unyieldable)
local Property = require(script.State.Property)
local Value = require(script.State.Value)

local function loadSolutions(root: Instance)
    for _, item in root:GetChildren() do
        if Configuration.EXCLUDES[item.Name:lower():gsub("%s+", "")] then continue end
        if item:IsA("Folder") then
            if item.Name:find(Configuration.SOLUTIONS_KEY) then
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
            loadSolutions(item)
        end
    end
end

loadSolutions(Configuration.ROOT)
loadSolutions(Configuration.SHARED_ROOT)

return {
    Class = Class,
    Promise = Promise,
    Profiler = Profiler,
    Signal = Signal,
    Value = Value,
    Ser = Ser,
    Property = Property,
    Symbol = Symbol,
    Unyieldable = Unyieldable,
}