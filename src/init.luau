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
local ClassConfiguration = require("@self/Class/Utility/Configuration")
local Registry = require("@self/Class/Utility/Registry")

local loaded = false

local Ignition = {
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

type IgnitionLinker = (_self: any, overrideDefinition: string?) -> _Ignition

type _Ignition = typeof(Ignition)
export type Ignition = typeof(setmetatable({}, {} :: { __index: _Ignition, __call: IgnitionLinker }))

local ExposedIgnition: Ignition = setmetatable({}, {
    __index = Ignition,
    __call = function(_, overrideDefinition: string?)
        if loaded then
            error("Ignition has already loaded", 2)
        end
        loaded = true

        if overrideDefinition then
            ClassConfiguration.HEADER_EXTENSION = overrideDefinition
        end

        local dependencies: { [string]: boolean } = {}

        -- load all solutions
        local function loadSolutions(root: Instance, fromSolutions: boolean?)
            for _, item in root:GetChildren() do
                if Configuration.EXCLUDES[item.Name:lower():gsub("%s+", "")] then continue end
                if item:IsA("Folder") then
                    if not fromSolutions then
                        fromSolutions = item.Name:find(`{Configuration.SOLUTIONS_KEY}$`) ~= nil
                    end
                    if fromSolutions then
                        for _, module in item:GetChildren() do
                            if module:IsA("ModuleScript") then
                                task.spawn(function()
                                    print(`Loading and linking {module:GetFullName()}`)
                                    local success, err = pcall(require, module)
                                    if not success then
                                        warn(`Failed to load {module:GetFullName()}\n\n[Linker Error]:\n{err}`)
                                        return
                                    end
                                    local name = module.Name:split(".")[1]
                                    dependencies[name] = true
                                    print(`Loaded and linked {module:GetFullName()}`)
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

        -- initialize dry-run classes to populate statics, warm up class-scoped registries and others concerned
        for name in dependencies do
            local interface = Registry.GetInterface(name)
            local dummy = interface:instantiate(false, true) -- ignore constructors since we are a dummy
            Class.delete(dummy) -- static fields are populated at this point
        end

        return Ignition
    end
})

return ExposedIgnition