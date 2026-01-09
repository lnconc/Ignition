--!strict
-- Class/Libs/nullable.lua

local Configuration = require("../Utility/Configuration")

local function nullable<T>(type: T): any
    return setmetatable({ type = type }, { __metatable = Configuration.NULLABLE_SIGNATURE })
end

return nullable