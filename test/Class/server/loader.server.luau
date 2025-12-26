--!nocheck
-- Server/loader.lua
local start = os.clock()
local files = script.Parent.files:GetDescendants()
local count = #files
warn(`Loading {count} files`)
for _, file in ipairs(files) do
	task.spawn(require, file)
end
warn(`Loaded {count} files in {os.clock() - start} seconds`)
script.Parent:SetAttribute("Loaded", true)