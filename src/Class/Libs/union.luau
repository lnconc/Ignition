--!strict
-- Class/Libs/union.lua

local Configuration = require("../Utility/Configuration")

local function union<T>(...: T): any
    local t = table.pack(...)
    for i = 1, t.n do
        local u = t[i]
        t[i] = nil
        t[u] = true
    end
    return setmetatable({ types = t :: { [T]: boolean } }, { __metatable = Configuration.UNION_SIGNATURE })
end

return union