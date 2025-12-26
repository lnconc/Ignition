--!strict
-- CLass/Private/nullable.lua

local Types = require(script.Parent.Parent.Types)
local Configuration = require(script.Parent.Parent.Utility.Configuration)

type Nullable<T> = Types.Nullable<T>

local function nullable<T>(type: T): Nullable<T>
    return setmetatable({ type = type }, { __metatable = Configuration.NULLABLE_SIGNATURE })
end

return nullable