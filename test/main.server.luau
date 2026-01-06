local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ignition = require(ReplicatedStorage.Ignition)("d")
local new = Ignition.Class.new
local dumpsize = Ignition.Class.dumpsize

-- Run MyClass Tests
local MyClass = new "MyClass"()
local function printThenEdit(source: any, target: string, newValue: any)
    warn(`\n\t\tKey: {target}`)
    xpcall(function()
        print(source[target])
        source[target] = newValue
        print(source[target])
    end, warn)
end

printThenEdit(MyClass, "Hello", "Roblox!")
printThenEdit(MyClass, "Readonly", "I can be edited outside!")
printThenEdit(MyClass, "Secret", "I'm not a secret anymore!")
print(`Secret: {MyClass:GetSecret()}`)
MyClass:RunAnonTest()

print(dumpsize())
Ignition.Profiler.new(50):run("AccessCache Performance", 5000, function(p)
    p:profilebegin("Private")
    for _ = 1, 2500 do
        local _ = MyClass:GetSecret() 
    end
    p:profileend()
end)
print(dumpsize())