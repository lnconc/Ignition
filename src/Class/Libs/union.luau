--!strict
-- Class/Libs/union.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Union<T> = Types.Union<T>

local function union<T>(...: T): Union<T>
    local t = table.pack(...)
    for i = 1, t.n do
        local u = t[i]
        t[i] = nil
        t[u] = true
    end
    return setmetatable({ types = t :: { [T]: boolean } }, { __metatable = Configuration.UNION_SIGNATURE })
end

return union