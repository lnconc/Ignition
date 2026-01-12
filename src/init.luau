--!strict
-- Ignition.lua

local Class = require("@self/Class")
local Configuration = require("@self/Configuration")
local State = require("@self/State")
local ClassConfiguration = require("@self/Class/Utility/Configuration")
local Registry = require("@self/Class/Utility/Registry")
local Log = require("@self/Log")
local Symbol = require("@self/Symbol")
local Unyieldable = require("@self/Unyieldable")

local loaded = false
local classes = {}

local Ignition = {
    extends = Class.extends,
    class = Class.class,
    abstract = Class.abstract,
    final = Class.final,
    mixin = Class.mixin,
    import = Class.import,
    ref = Class.ref,
    super = Class.super,
    property = Class.property,
    new = Class.new,
    reactive = Class.reactive,
    nullable = Class.nullable,
    func = Class.func,
    union = Class.union,
    free = Class.free,
    anon = Class.anon,
    dumpsize = Class.dumpsize,
    delete = Class.delete,
    friend = Class.friend,
    mutual = Class.mutual,
    unwrap = Class.unwrap,
    PLACEHOLDER = Class.PLACEHOLDER,
    FLAGS = Class.FLAGS,
    METADATA = Class.METADATA,

    Value = State.Value,
    Property = State.Property,
    Observe = State.Observe,
    peek = State.peek,

    Symbol = Symbol,
    Unyieldable = Unyieldable,
    Class = Class,
}

function Ignition.GetClasses()
    return classes
end

type IgnitionLinker = (_self: any, overrideDefinition: string?) -> _Ignition

type _Ignition = typeof(Ignition)
export type Ignition = typeof(setmetatable({}, {} :: { __index: _Ignition, __call: IgnitionLinker }))

local ExposedIgnition: Ignition = setmetatable({}, {
    __index = Ignition,
    __call = function(_, overrideDefinition: string?)
        if loaded then
            Log.ALREADY_LOADED:throw(2)
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
                        local children = item:GetChildren()
                        for _, module in children do
                            if module:IsA("ModuleScript") then
                                task.spawn(function()
                                    local success, classOrErr = pcall(require, module)
                                    if not success then
                                        warn(`Failed to load {module:GetFullName()}\n\n[Linker Error]:\n{classOrErr}`)
                                        return
                                    end
                                    local name = module.Name:split(".")[1]
                                    if module.Name:sub((#name)+2) ~= ClassConfiguration.HEADER_EXTENSION then
                                        classes[name] = classOrErr
                                    end
                                    dependencies[name] = true
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