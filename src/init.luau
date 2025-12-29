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

--#region If you are using wally, copy all of these and replace them with `Ignition` to your `Ignition.lua` file under `Packages`
export type Promise = Promise.Promise
export type Signal = Signal.Signal
export type Connection = Signal.Connection
export type func = Class.func
export type class = Class.class
export type extends = Class.extends
export type abstract = Class.abstract
export type final = Class.final
export type mixin = Class.mixin
export type import = Class.import
export type ref = Class.ref
export type super = Class.super
export type property = Class.property
export type new = Class.new
export type reactive = Class.reactive
export type once = Class.once
export type nullable = Class.nullable
export type union = Class.union
export type free = Class.free
export type FLAGS = Class.FLAGS
export type METADATA = Class.METADATA
export type PLACEHOLDER = Class.PLACEHOLDER
export type PRODUCTION_MODE_ENABLED = boolean
--#endregion

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
                                    local success, err = pcall(require, module)
                                    if not success then
                                        warn(`Failed to load {module:GetFullName()}\n\n[Linker Error]:\n{err}`)
                                        return
                                    end
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
        return Ignition
    end
})

return ExposedIgnition