--!strict
-- Class/Utility/Registry.lua

local getCaller = require("../../Internal/getCaller")
local Log = require("../../Log")
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
local function assertCallingScript(...: string?)
    local caller = getCaller(2)
    if not caller:IsDescendantOf(ANCESTOR) and caller ~= ANCESTOR then
        Log.OUT_OF_SCOPE:throw(2, caller.Name)
    else
        local names = table.pack(...)
        if names.n > 0 then
            for _, name in ipairs(names) do
                if name ~= caller.Name then
                    Log.ILLEGAL_REGISTRY_CALL:throw(2)
                end
            end
        end
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
            Log.WAIT_INTERFACE_TIMEOUT:throw(2, name)
        else
            task.cancel(delay)
        end
        return result
    end
    return Interfaces[name]
end

function Registry.SaveInterface(interface: Interface, name: string)
    assertCallingScript("class")
    if Registry.InterfaceExists(name) then
        Log.CLASS_EXISTS:throw(2, name)
    end
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
    assertCallingScript("class")
    ObjectEnvironments[object] = environment
end

function Registry.GetEnvironment(object: any): Types.Environment
    assertCallingScript("delete", "friend")
    local env = ObjectEnvironments[object]
    if not env then
        Log.OBJECT_NOT_FOUND:throw(2)
    end
    return env
end

function Registry.HasInterface(interface: any): boolean
    assertCallingScript()
    for _, i in pairs(Interfaces) do
        if i == interface then return true end
    end
    return false
end

function Registry.HasObject(object: any): boolean
    assertCallingScript("friend", "xtypeof")
    return ObjectEnvironments[object] ~= nil
end

function Registry.LinkData(object: any, data: any)
    assertCallingScript("delete")
    ObjectDatas[object] = data
end

function Registry.GetData(object: any): any
    assertCallingScript("delete", "friend")
    local data = ObjectDatas[object]
    if not data then
        Log.OBJECT_NOT_FOUND:throw(2)
    end
    return data
end

function Registry.PurgeObject(object: any)
    assertCallingScript("delete")
    ObjectEnvironments[object] = nil
    ObjectDatas[object] = nil
end

return Registry