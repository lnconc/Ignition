--!nocheck
-- Server/main.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not script:GetAttribute("Loaded") then
    script:GetAttributeChangedSignal("Loaded"):Wait()
end

local new = require(ReplicatedStorage.Ignition.Class).new

local SIZE = 100
local MyClass = new "MyClass"()

warn("\n\nBenchmarking Class by lnconcinnity")
MyClass:run(SIZE)
script:SetAttribute("Finished", true)