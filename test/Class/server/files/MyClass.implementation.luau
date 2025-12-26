--!nocheck
-- MyClass.implementation.lua
local Profiler = require(game.ReplicatedStorage.Ignition.Modules.Profiler)
local Class = require(game.ReplicatedStorage.Ignition.Class)

local import, super, ref, once = Class.import, Class.super, Class.ref, Class.once
if once() then return {} end

local format, random = string.format, math.random

local MyClass = import()
MyClass(function(self)
    warn(`Creating {tostring(self)}`)
    super()
    warn(`{tostring(self)} created`)
end)

function MyClass:run(SIZE: number)
    local function trySnooping(label: string, option: { some: string, none: string }, exec: any)
        local success = pcall(exec)
        warn(`{label} {if success then option.some else option.none}`)
    end
    local function createProfiler(label: string, batches: number, exec: any)
        Profiler.new():run(label, batches, exec)
    end

    trySnooping("Can I access my parent's PIN number?", { some = "Yes, I can!", none = "Nope, I can't!" })

    createProfiler("public: read-write operation", 256, function(profile)
        profile:profilebegin("read")
        for _ = 1, SIZE do
            local _message = self.Message
        end
        profile:profileend()
        
        profile:profilebegin("write")
        for _ = 1, SIZE do
            self.Message = format("%08X", random(0, 0x7FFFFFFF))
        end
        profile:profileend()
    end)

    createProfiler("private: read-write operation", 256, function(profile)
        profile:profilebegin("read")
        for _ = 1, SIZE do
            local _secret = self.Secret
        end
        profile:profileend()
        
        profile:profilebegin("write")
        for _ = 1, SIZE do
            self.Secret = format("%08X", random(0, 0x7FFFFFFF))
        end
        profile:profileend()
    end)

    createProfiler("protected: read-write operation", 256, function(profile)
        profile:profilebegin("read")
        for _ = 1, SIZE do
            local _whisper = self.Whisper
        end
        profile:profileend()
        
        profile:profilebegin("write")
        for _ = 1, SIZE do
            self.Whisper = format("%08X", random(0, 0x7FFFFFFF))
        end
        profile:profileend()
    end)
end

return {}