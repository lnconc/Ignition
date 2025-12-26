--!strict
-- Class/Utility/Registry.lua

local env = require(script.Parent.Parent.Parent.Internal.env)
local getCaller = require(script.Parent.Parent.Parent.Internal.getCaller)
local Types = require(script.Parent.Parent.Types)

type Map<K, V> = Types.Map<K, V>
type Set<T> = Types.Set<T>
type Interface = Types.Interface

local ANCESTOR = script.Parent.Parent

local Registry = {}
local InterfaceYields, LinkYields = {}, {}
local Interfaces: Map<string, Interface> = setmetatable({}, { __mode = "v" })

-- restrict access only within the Class folder; not necessarily an anti-cheat, just to prevent misuse
-- ex. if you call SaveInterface without using the `class` module found in the private folder, this will error
local function assertCallingScript()
    local caller = getCaller(2)
    if not caller:IsDescendantOf(ANCESTOR) then
        error("attempt to call Registry-related functions outside of Class scope", 2)
    end
end

function Registry.WaitForInterface(name: string): Interface
    assertCallingScript()
    if not Interfaces[name] then
        local thread = coroutine.running()
        local group: Set<thread> = InterfaceYields[name] or {}
        group[thread] = true
        InterfaceYields[name] = group
        return coroutine.yield()
    end
    return Interfaces[name]
end

function Registry.SaveInterface(interface: Interface, name: string)
    assertCallingScript()
    assert((Interfaces[name] :: any | nil) == nil, `class {name} already exists`)
    Interfaces[name] = interface
    if InterfaceYields[name] then
        for t in pairs(InterfaceYields[name]) do
            task.spawn(t :: thread, interface)
        end
    end
    InterfaceYields[name] = nil
end

function Registry.WaitForLink(name: string): Interface
    local interface = Interfaces[name]
    if not interface then
        interface = Registry.WaitForInterface(name)
    end
    if interface.flags.InheritanceLinked then
        return interface
    end
    local thread = coroutine.running()
    local group: Set<thread> = LinkYields[name] or {}
    group[thread] = true
    LinkYields[name] = group
    return coroutine.yield()
end

function Registry.SignalLink(name: string, interface: Interface)
    if LinkYields[name] then
        for t in pairs(LinkYields[name]) do
            task.spawn(t :: thread, interface)
        end
        LinkYields[name] = nil
    end
end

function Registry.GetInterface(name: string): Interface
    assertCallingScript()
    return assert(Interfaces[name], `class {name} does not exist`)
end

function Registry.InterfaceExists(name: string): boolean
    assertCallingScript()
    return Interfaces[name] ~= nil
end

function Registry.UpsertTask(task: any, level: (number | boolean)?)
    assertCallingScript()
    local _, fn, exp = getCaller(if level ~= nil then level else 1)
    if not exp.class_tasks then
        env.set(fn :: any, { class_tasks = { task }})
    else
        table.insert(exp.class_tasks, task)
    end
end

function Registry.FlushTasks(level: number?, ...: any)
    assertCallingScript()
    local _, _, exp = getCaller(level or 1)
    if exp.class_tasks then
        for _, t in ipairs(exp.class_tasks) do
            task.spawn(t :: thread, ...)
        end
        table.clear(exp.class_tasks)
    end
end

return Registry