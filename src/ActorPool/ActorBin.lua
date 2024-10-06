local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

type MessageContent = {
    ref: string?,
    reply: string,
    target: string,
    args: {any} | {[string]: any},
}

local PolledValuesToReflect = {}
local ReflectedValue = {} do
    local function pollValue(value: any, key: string, refId: string)
        if not PolledValuesToReflect[refId] then
            PolledValuesToReflect[refId] = {}
        end
        PolledValuesToReflect[refId][key] = value
    end

    local ReflectedValueAPI = {}
    function ReflectedValueAPI:get(): ReflectedValue
        return self._value
    end

    function ReflectedValueAPI:set(value: any, force: boolean?)
        if self._value ~= value or force == true then
            task.spawn(pollValue, value, self._key, self._refId)
            self._value = value
        end
    end

    function ReflectedValue.new<T>(initialValue: T, key: string, ref: string): ReflectedValue
        local Value = {}
        Value._key = key
        Value._refId = ref
        Value._value = initialValue
        return setmetatable(Value, {__index = ReflectedValueAPI, __tostring = function(self)
            return if type(self._value) == "table" then self._value else tostring(self._value)
        end})
    end
    type ReflectedValue = typeof(ReflectedValue.new('test'))
end

local CurrentReflectedClasses = {}
local ReflectedClass = {} do
    local INTERNAL_PROPERTIES = {
        ['expose'] = true,
        ['deleteInternal'] = true,
        ['_ref'] = true,
    }

    local ReflectedClassAPI = {}
    function ReflectedClassAPI:expose(...: string)
        for _, key in next, {...} do
            self[key] = ReflectedValue.new(self[key], key, self._ref)
        end
    end

    function ReflectedClass:deleteInternal()
        CurrentReflectedClasses[self._ref] = nil
        setmetatable(self, nil)
    end

    function ReflectedClass.new(fromClass)
        local class = {}
        function class.new<U...>(ref: string, ...: U...)
            local self = {}
            self._ref = ref
            setmetatable(self, {__index = function(_self, key: any)
                return rawget(_self, key) or ReflectedClassAPI[key]
            end, __newindex = function(_self, key: any, value: any)
                if type(key) == "string" and INTERNAL_PROPERTIES[key:lower()] ~= nil then
                    error('attempt to modify internal method')
                end
                rawset(_self, key, value)
            end})

            local values = nil
            if type(fromClass.__prototype_init__) == "function" then
                fromClass.__prototype_init__(self, ...)
                for key, value in pairs(self) do
                    if type(value) == "table" and type(value.get) == "function" then
                        if not values then
                            values = {}
                        end
                        values[key] = value._value
                    end
                end
            end

            return {
                class = self,
                values = values
            }
        end

        for key, value in fromClass do
            if key:lower() == 'new' or key:lower() == 'create' or key:lower() == 'init' then
                continue -- ignore already made constructors
            end
            class[key] = value
        end
        return table.freeze(class)
    end
end

return function(actor: Actor, subscriber: Instance)
    local taskCompleted = subscriber:WaitForChild("TaskCompleted") :: BindableEvent
    local dependency = require(subscriber:WaitForChild("LinkedScript").Value :: ModuleScript)
    dependency = ReflectedClass.new(dependency)

    local function publishReply(replyContent: {any} | {[string]: any}, replyId: string?, refId: string?, reflectingValues: boolean?)
        task.synchronize()
        taskCompleted:Fire({
            ref = refId,
            reply = replyId,
            content = replyContent,
            reflectingValues = reflectingValues,
        })
    end
    
    local flushingReflectedValues = false
    local function reflectExposedValues()
        local polled = PolledValuesToReflect
        PolledValuesToReflect = {}
        for refId, polledReplies in pairs(polled) do
            publishReply(polledReplies, nil, refId, true)
        end
        flushingReflectedValues = false
    end

    RunService.Stepped:Connect(function(_t, _dt)
        if not flushingReflectedValues then
            flushingReflectedValues = true
            task.defer(reflectExposedValues)
        end
    end)
    
    actor:BindToMessageParallel('initPrototype', function(content: MessageContent)
        local ref = HttpService:GenerateGUID(false)
        local obj = dependency.new(ref, table.unpack(content.args))
        CurrentReflectedClasses[ref] = obj.class
        publishReply({
            [1] = ref,
            [2] = obj.values,
        }, content.reply)
    end)
    
    actor:BindToMessageParallel('updateValuesFor', function(content: MessageContent)
        print(content)
        local reflected = CurrentReflectedClasses[content.ref]
        if not reflected then
            error(`class "{content.ref}" does not exist`)
        end
        
        local incidents = {}
        for key, value in pairs(content.args) do
            local valueObj = reflected[key]
            if not valueObj then
                warn(`reflected value "{key}" does not exist`)
                incidents[#incidents+1] = key
                continue
            end
            valueObj:set(value) -- dont force, we prioritize values from the actor vm and not from the main vm
        end
        publishReply({
            [1] = incidents
        }, content.reply)
    end)
    
    actor:BindToMessageParallel('runTask', function(content: MessageContent)
        print(content)
    end)
end