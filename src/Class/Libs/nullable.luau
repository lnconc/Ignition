--!strict
-- CLass/Libs/nullable.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")

type Nullable<T> = Types.Nullable<T>

local function nullable<T>(type: T): Nullable<T>
    return setmetatable({ type = type }, { __metatable = Configuration.NULLABLE_SIGNATURE })
end

return nullable