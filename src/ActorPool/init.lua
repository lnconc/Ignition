--!native
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Symbol = require(script.Parent.Symbol)
local Set = require(script.Parent.Set)

type TaskResponse = {reply: string, ref: string?, reflectingValues: boolean?, content: {[string]: any} | {any}}

local IS_SERVER = RunService:IsServer()

local PROTOTYPE_INIT_SYMBOL = Symbol('__prototype_init__')
local RUN_FUNCTION_SYMBOL = Symbol('__run_function__')
local MESSAGE_PARALLEL_SYMBOL = Symbol('__message_parallel__')
local VALID_MODES = Set('runTask', 'updateValuesFor', 'initPrototype')

local Bin = script:FindFirstChild("ActorBin")
if not Bin then
    error("dependency Actor.ActorBin is missing", 3)
end
local SubscriberTemplate = if IS_SERVER then script:WaitForChild("ServerSubscriber") else script:WaitForChild("ClientSubscriber")
if IS_SERVER then
    Bin = Bin:Clone()
    Bin.Parent = game:GetService("ServerScriptService")
else
    Bin.Parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
end

local Dependencies = {}
local function loadDependency(dependency: ModuleScript)
    local content = require(dependency)
    local d = {
    }
    for key, value in pairs(content) do
        d[key] = typeof(value)
    end
    Dependencies[dependency] = d
end

local CurrentClassReflectors = {
    reflectors = {}, -- the ActorObj[RUN_FUNCTION_SYMBOL]
    polledToUpdate = {}, -- updates for the reflector classes
    polledForUpdate = {}, -- updates for the reflected classes
    flushingToUpdate = false,
    flushingForUpdate = false,
}
local function pollUpdate(mode: 'ToUpdate' | 'ForUpdate', refId: string, key: string, value: any)
    local container = CurrentClassReflectors[`polled{mode}`]
    if not container[refId] then
        container[refId] = {}
    end
    container[refId][key] = value

    local _flush = `flushing{mode}`
    if not CurrentClassReflectors[_flush] then
        CurrentClassReflectors[_flush] = true
        task.defer(function()
            local polled = container[refId]
            if polled then
                container[refId] = {}
                local reflector = CurrentClassReflectors.reflectors[refId]
                if not reflector then
                    error(`no reflection publishers for reference "{refId}"`)
                end
                if mode == 'ForUpdate' then
                    local incidents = table.unpack(reflector.updateReferencedValues(polled))
                    if incidents ~= nil and #incidents > 0 then
                        warn(`referenced values [{table.concat(incidents, ', ')}] does not exist for referenced class "{refId}"`)
                    end
                else
                    for polledKey, polledValue in pairs(polled) do
                        local valueObj =  reflector.class[polledKey]
                        if not valueObj then
                            warn(`exposed value "{polledKey}" does not exist`)
                            continue
                        end

                        if type(valueObj) ~= "table" or (type(valueObj) == "table" and type(valueObj.get) ~= "function") then
                            warn(`exposed "value" "{polledKey}" is not a valid reflected value`)
                            continue
                        end

                        valueObj._value = polledValue -- do not use :set(), this would loop
                        valueObj._touched = false
                    end
                end
            end
            CurrentClassReflectors[_flush] = false
        end)
    end
end

local ClassReflector = {}
function ClassReflector.new(superClass: {Actor: Actor, [string]: () -> ()}, refId: string, exposedValues: {[string]: any})
    local reflecedClass = {}

    for key, value in next, superClass do
        if type(value) == "function" then
            -- recreate our functions with refid included
            reflecedClass[key] = function(...)
                return superClass[RUN_FUNCTION_SYMBOL]({
                    target = key,
                    refId = refId,
                    args = {...},
                })
            end
        end
    end

    if exposedValues ~= nil and next(exposedValues) ~= nil then
        local function createReflectedValue<T>(initialValue: T, key: string)
            local Value = {}
            Value._touched = false -- sets to true when value is changed, used to determine if the value actually has been updated by the actor (internally)
            Value._value = initialValue
            function Value:set(value: T, forced: boolean?)
                if (value ~= self._value or forced == true) and not self._touched then -- self._touched is used to avoid sending ghost values; values that are lost in the event queue
                    self._touched = true
                    pollUpdate("ForUpdate", refId, key, value)
                end
            end
            function Value:get(): T
                return self._value
            end
            function Value:isfree()
                return self._touched == false
            end
            return setmetatable(Value, {__tostring = function(self)
                return if type(self._value) == "table" then self._value else tostring(self._value)
            end})
        end

        for key, exposedValue in pairs(exposedValues) do
            reflecedClass[key] = createReflectedValue(exposedValue, key)
        end
    end
    reflecedClass = table.freeze(reflecedClass)
    CurrentClassReflectors.reflectors[refId] = {
        updateReferencedValues = function(polled: {[string]: any})
            return superClass[MESSAGE_PARALLEL_SYMBOL]({
                mode = 'updateValuesFor',
                refId = refId,
            }, polled)
        end,
        class = reflecedClass,
    }
    return reflecedClass
end

local Actor = {}
function Actor.new(body: {
    targetDependency: ModuleScript?,
    dependencyActor: Actor?,
})
    assert(body.targetDependency:IsA("ModuleScript"), `body.targetDependency must be a ModuleScript`)
    assert(body.dependencyActor:IsA("Actor"), `body.dependencyActor must be an Actor`)
    local dependency = assert(Dependencies[body.targetDependency], `dependency {body.targetDependency.Name} does not exist`)

    local self = {}
    self.Actor = body.dependencyActor
    self.TaskCompleted = self.Actor:WaitForChild(`{if IS_SERVER then 'Server' else 'Client'}Subscriber`).TaskCompleted.Event
    self._valuesUpdatePoller = self.TaskCompleted:Connect(function(response: TaskResponse)
        if response.reflectingValues and not response.reply then
            for key, value in pairs(response.content) do
                pollUpdate("ToUpdate", response.ref, key, value)
            end
        end
    end)

    local hasInitialization = false 
    local function parallelFunctionWrapper(wrapperBody: {
        mode: 'runTask' | 'updateValuesFor' | 'initPrototype' | 'getValue',
        target: string?,
        refId: string?,
    }, args: {any})
        print(args)
        assert(VALID_MODES:contains(wrapperBody.mode), `mode "{wrapperBody.mode}" is not part of modes {VALID_MODES:list()}`)
        local replyId = HttpService:GenerateGUID(false)
        body.dependencyActor:SendMessage(wrapperBody.mode, {
            ref = wrapperBody.refId,
            reply = replyId,
            target = wrapperBody.target,
            args = args,
        })
        local thread = coroutine.running()
        local conn; conn = self.TaskCompleted:Connect(function(response: TaskResponse)
            if (response.reply == replyId) and (if wrapperBody.refId ~= nil then response.ref == wrapperBody.refId else true) then
                task.spawn(thread, response.content)
                conn:Disconnect()
                conn = nil
            end
        end)
        local out = coroutine.yield()
        return out
    end
    self[MESSAGE_PARALLEL_SYMBOL] = parallelFunctionWrapper

    -- wrapper for all functions
    self[RUN_FUNCTION_SYMBOL] = function(wrapperBody: {
        target: string,
        refId: string?,
        args: {any}
    })
        local returns = parallelFunctionWrapper({
            mode = 'runTask',
            ref = wrapperBody.refId,
            target = wrapperBody.target,
        }, wrapperBody.args)
        return table.unpack(returns)
    end

    for key, type in dependency do
        if type ~= "function" then continue end
        if not hasInitialization and key:lower() == '__prototype_init__' then
            hasInitialization = true
            continue -- do not make a __prototype_init__ call
        end
        self[key] = function(...)
            return self[RUN_FUNCTION_SYMBOL]({
                target = key,
                refId = nil,
                args = {...},
            })
        end
    end

    if hasInitialization then
        self[PROTOTYPE_INIT_SYMBOL] = function(...)
            local refId, exposedValues = table.unpack(parallelFunctionWrapper({
                mode = 'initPrototype',
            }, {...}))
            return ClassReflector.new(self, refId, exposedValues)
        end
    end

    return table.freeze(self)
end
type RunningActorComponent = typeof(Actor.new())

local function createActor(dependency: ModuleScript)
    local actor = Instance.new("Actor")
    local subscriber = SubscriberTemplate:Clone()
    subscriber.LinkedScript.Value = dependency

    subscriber.Disabled = false
    subscriber.Parent = actor

    actor.Parent = Bin
    return {
        RunningComponent = Actor.new({
            targetDependency = dependency,
            dependencyActor = actor
        }),
        Working = false,
    }
end

local function tryGetFreeActorFrom(pool: typeof({}), count: number, queue: typeof({})): ({RunningComponent: RunningActorComponent, Working: boolean}, number)
    local currentActor = nil
    for _ = 1, count do
        local actor = pool[_]
        if not actor.Working then
            currentActor = actor
        end
    end
    local queuedPosition = -1
    if not currentActor then
        local thread = coroutine.running()
        queuedPosition = #queue+1
        queue[queuedPosition] = thread
        currentActor = coroutine.yield()
    end
    currentActor.Working = true
    return currentActor, queuedPosition
end

local ActorPoolAPI = {}

function ActorPoolAPI:Take<U...>(...: U...): any
    local currentActor, queueIndex = tryGetFreeActorFrom(self._actors, self._actorCount, self._queued)
    if not currentActor.RunningComponent[PROTOTYPE_INIT_SYMBOL] then
        -- free the actor
        if queueIndex > 0 then
            table.remove(self._queued, queueIndex)
        end
        currentActor.Working = false
        error(`the actor's dependency has no prototype (missing constructor)`)
    end
    local prototype = currentActor.RunningComponent[PROTOTYPE_INIT_SYMBOL](...)
    return prototype
end

function ActorPoolAPI:TakeAsync<U...>(...: U...): any
    local actor = createActor(self._dependency)
    actor.Working = nil -- temporary actor, no need to have the working key
    actor.RunningComponent.TaskCompleted:Once(function()
        actor.RunningComponent:Destroy()
        actor.RunningComponent = nil
    end)
    if not actor.RunningComponent[PROTOTYPE_INIT_SYMBOL] then
        error(`the actor's dependency has no prototype (missing constructor)`)
    end
    local prototype = actor.RunningComponent:__prototype_init__(...)
    return prototype
end

function ActorPoolAPI:Run<U...>(fnName: string, ...: U...): (...any)
    local currentActor, _queueIndex = tryGetFreeActorFrom(self._actors, self._actorCount, self._queued)
    return currentActor
end

local ActorPool = {}
function ActorPool.new(dependency: ModuleScript, capacity: number?)
    assert(typeof(dependency) == "Instance" and dependency:IsA("ModuleScript"), "argument 1 expects a ModuleScript")
    local self = {}
    self._dependency = dependency
    task.spawn(loadDependency, dependency)
    self._actors = {}
    self._queued = {}
    self._actorCount = math.max(capacity or 10, 1)
    for _ = 1, self._actorCount do
        local actor = createActor(dependency)
        actor.RunningComponent.TaskCompleted:Connect(function(response: TaskResponse)
            if #self._queued > 0 then
                local thread = table.remove(self._queued, 1)
                if not thread then
                    warn(`missed queued thread, must have been closed before a previous operation was completed (replyId: {response.reply}`)
                    return
                end
                task.spawn(thread, actor)
            end
        end)
        self._actors[_] = actor
    end
    setmetatable(self, {__index = ActorPoolAPI})
    return table.freeze(self)
end

return ActorPool