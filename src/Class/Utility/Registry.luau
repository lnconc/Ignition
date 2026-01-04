--!strict
-- Class/Utility/Registry.lua

local getCaller = require("../../Internal/getCaller")
local Types = require("../Types")

type Interface = Types.Interface
type Yields = { [string]: { [thread]: boolean } }

local ANCESTOR = script.Parent.Parent
local TIMEOUT_DURATION = 8

local Registry = {}
local InterfaceYields: Yields, LinkYields: Yields = {}, {}
local Interfaces: { [string]: Interface } = setmetatable({}, { __mode = "v" })
local ObjectEnvironments: { [any]: Types.Environment } = setmetatable({}, { __mode = "k" })
local ObjectDatas: { [any]: any } = setmetatable({}, { __mode = "k" })

-- restrict access only within the Class folder; not necessarily an anti-cheat, just to prevent misuse
-- ex. if you call SaveInterface without using the `class` module found in the private folder, this will error
local function assertCallingScript(callerName: string?)
    local caller = getCaller(2)
    if not caller:IsDescendantOf(ANCESTOR) and caller ~= ANCESTOR then
        error(`attempt to call Registry-related functions outside of Class scope (current caller: {caller.Name})`, 2)
    end
    if callerName and callerName ~= caller.Name then
        error(`attempt to illegally call Registry-related functions out of caller scope`)
    end
end

function Registry.WaitForInterface(name: string): Interface
    assertCallingScript()
    if not Interfaces[name] then
        local thread = coroutine.running()
        local group = InterfaceYields[name] or {}
        group[thread] = true
        InterfaceYields[name] = group

        local delay = task.delay(TIMEOUT_DURATION, function()
            if InterfaceYields[name] and InterfaceYields[name][thread] then
                InterfaceYields[name][thread] = nil
                task.spawn(thread, "TIMEOUT")
            end
        end)

        local result = coroutine.yield()
        if not result then
            error(`Infinite yield for WaitForInterface whilst waiting for Class "{name}"`)
        else
            task.cancel(delay)
        end
        return result
    end
    return Interfaces[name]
end

function Registry.SaveInterface(interface: Interface, name: string)
    assertCallingScript("class")
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
    assertCallingScript()
    local interface = Interfaces[name]
    if not interface then
        interface = Registry.WaitForInterface(name)
    end
    if interface.flags.InheritanceLinked then
        return interface
    end
    local thread = coroutine.running()
    local group = LinkYields[name] or {}
    group[thread] = true
    LinkYields[name] = group
    return coroutine.yield()
end

function Registry.SignalLink(name: string, interface: Interface)
    assertCallingScript("class")
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

function Registry.SaveEnvironment(object: any, environment: Types.Environment)
    assertCallingScript("delete")
    ObjectEnvironments[object] = environment
end

function Registry.GetEnvironment(object: any): Types.Environment
    assertCallingScript("delete")
    local env = ObjectEnvironments[object]
    if not env then
        error("Attempt to access environment of a non-Ignition object or deleted instance", 2)
    end
    return env
end

function Registry.LinkData(object: any, data: any)
    assertCallingScript("delete")
    ObjectDatas[object] = data
end

function Registry.GetData(object: any): any
    assertCallingScript("delete")
    local data = ObjectDatas[object]
    if not data then
        error("Attempt to access data of a non-Ignition object or deleted instance", 2)
    end
    return data
end

function Registry.PurgeObject(object: any)
    assertCallingScript("delete")
    ObjectEnvironments[object] = nil
    ObjectDatas[object] = nil
end

return Registry