--!strict
-- Utility/Symbol.lua

local Types = require("../Types")

export type Symbol<T> = Types.Symbol<T>

local Symbol = {}
function Symbol.new<T>(id: T): Symbol<T>
    local symbol = newproxy(true)
    local mt = getmetatable(symbol)
    mt.__tostring = function(): string
        return `Symbol<{id}>`
    end
    mt.__metatable = id
    mt.__call = function() end -- identity function
    return symbol
end

return Symbol.new