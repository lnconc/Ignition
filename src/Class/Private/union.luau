--!strict
-- CLass/Private/union.lua

local Types = require(script.Parent.Parent.Types)
local Configuration = require(script.Parent.Parent.Utility.Configuration)

type Union<T> = Types.Union<T>

local function nullable<T>(types: T): Union<T>
    return setmetatable({ types = types }, { __metatable = Configuration.UNION_SIGNATURE })
end

return nullable