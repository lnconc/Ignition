--!native
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

local Bin = script:FindFirstChild("ActorBin")
if not Bin then
    error("dependency Actor.ActorBin is missing", 3)
end
local SubscriberTemplate = if IS_SERVER then script:WaitForChild("ServerSubscriber") else script:WaitForChild("ClientSubscriber")

if IS_SERVER then
    Bin = Bin:Clone()
    Bin = game:GetService("ServerScriptService")
else
    Bin = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
end

local Dependencies = {}
local function loadDependency(dependency: ModuleScript)
    local content = require(dependency)
    local d = {
    }
    for key in pairs(content) do
        local type = typeof(key)
        d[key] = type
    end
    Dependencies[dependency] = d
end

local Actor = {}
function Actor.new(targetDependency: Instance)
    local dependency = Dependencies[targetDependency]
    
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
        RunningComponent = Actor.new(),
        Working = false,
    }
end

local ActorPoolAPI = {}
function ActorPoolAPI:Take<U...>(...: U...): RunningActorComponent
    
end

function ActorPoolAPI:TakeAsync<U...>(...: U...): RunningActorComponent
    local actor = createActor(self._dependency)
    actor.Working = nil -- temporary actor, no need to have the working key
    actor.RunningComponent.OnMessageReceived:Once(function()
        actor.RunningComponent:Destroy()
    end)
    return actor.RunningComponent
end

local ActorPool = {}
function ActorPool.new(dependency: ModuleScript, capacity: number?)
    assert(typeof(dependency) == "Instance" and dependency:IsA("ModuleScript"), "argument 1 expects a ModuleScript")
    local self = {}
    self._dependency = dependency
    task.spawn(loadDependency, dependency)
    self._actors = {}
    self._queued = {}
    for _ = 1, math.max(capacity or 10, 1) do
        self._actors[_] = createActor(dependency)
    end
    setmetatable(self, ActorPoolAPI)
    return self
end

return ActorPool