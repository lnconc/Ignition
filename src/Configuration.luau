--!strict
-- Ignition/Configuration.lua

local function set<T>(...: T): { [T]: boolean }
    local s = table.pack(...)
    for i = s.n, 1, -1 do
        local t = s[i]
        s[i] = nil
        s[t] = true
    end
    return s
end

return {
    VERSION = "v1.0.5",
    ROOT = if game:GetService("RunService"):IsServer() 
    then game:GetService("ServerScriptService") 
    else game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"),
    SHARED_ROOT = game:GetService("ReplicatedStorage"),
    EXCLUDES = set("assets", "templates", "prefabs", "temp"),
    SOLUTIONS_KEY = "Solution",
}