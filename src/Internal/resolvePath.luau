--!strict
-- Class/Utility/resolvePath.lua

local Configuration = require("../Class/Utility/Configuration")
local HEADER_EXTENSION = Configuration.HEADER_EXTENSION

local function resolvePath(path: string): any
    local segments = {}
    for segment in string.gmatch(path, "([^%.]+)") do
        table.insert(segments, segment)
    end

    local i = 1
    while i <= #segments do
        if string.find(segments[i], "@") and i < #segments then
            while i < #segments and (tonumber(segments[i+1]) or string.match(segments[i+1], "^%d+")) do
                segments[i] = segments[i] .. "." .. (table.remove(segments, i+1) :: string)
            end
        end
        i += 1
    end

    local extension = if HEADER_EXTENSION:sub(1, 1) == "." then HEADER_EXTENSION:sub(2) else HEADER_EXTENSION
    local last = #segments
    if segments[last] == extension then
        local fileName = segments[last - 1] .. "." .. extension
        segments[last - 1], segments[last] = nil, nil
        table.insert(segments, fileName)
    end

    local serviceName = table.remove(segments, 1)
    local current = game:GetService(serviceName :: string)

    for _, segment in ipairs(segments) do
        if current then
            current = current:FindFirstChild(segment)
        end
        
        if current == nil then 
            warn(`[Ignition Error] Could not resolve segment "{segment}" in path "{path}"`)
            return nil 
        end
    end

    return current
end

return resolvePath