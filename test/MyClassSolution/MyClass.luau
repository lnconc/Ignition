--!strict
-- MyClass.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignition = require(ReplicatedStorage.Ignition)
local Class = Ignition.Class

local import, ref, free, anon = Class.import, Class.ref, Class.free, Class.anon

local MyClassHeader = require("./MyClass.d")
local MyClass = import(MyClassHeader)
type MyClassInstance = typeof(MyClass)

MyClass(function(self: MyClassInstance)
    warn(`\n\t\tKey: Readonly`)
    print(self.Readonly)
    self.Readonly = "I'm edited from the constructor!"
    print(self.Readonly)
end)

function MyClass:GetSecret()
    return self.Secret
end

function MyClass:RunAnonTest()
    print("Method Level: Accessing Secret ->", self.Secret)

    local internalTask = anon(function(suffix: string)
        print("Anon Level: Accessing Secret ->", (self.Secret :: any) .. suffix)
    end)
    internalTask(" (Captured via Anon!)")
    
    local wrapperA = anon(function() end)
    local wrapperB = anon(function() end)
    
    print("Deduplication Test: ", tostring(wrapperA) == tostring(wrapperB))
end

return MyClass:__complete__()