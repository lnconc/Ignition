--!strict
-- Class/Utility/resolvePath.lua

local Configuration = require("../Class/Utility/Configuration")

local function resolvePath(path: string): any
    local segments = string.split(path, ".")
    local extension = Configuration.HEADER_EXTENSION
    local last = #segments
    if segments[last] == extension then
        local fileName = segments[last - 1] .. "." .. extension
        segments[last - 1], segments[last] = nil, nil
        table.insert(segments, fileName)
    end
    local current = game:GetService(table.remove(segments, 1) :: string) :: Instance

    for _, segment in ipairs(segments) do
        if typeof(current) == "Instance" then
            current = current:FindFirstChild(segment)
        end
        if current == nil then 
            warn(`Could not resolve segment "{segment}" in path "{path}"`)
            return nil 
        end
    end

    return current
end

return resolvePath