--!strict
-- Modules/Symbol.lua

export type Symbol<T> = setmetatable<{}, {
    __tostring: () -> string,
    __metatable: T,
    __call: () -> (),
}>

local Symbol = {}
function Symbol.new<T>(id: T): Symbol<T>
    local symbol = newproxy(true)
    local mt = getmetatable(symbol)
    mt.__tostring = function(): string
        return `Symbol<{id}>`
    end
    mt.__metatable = id
    mt.__call = function() end -- identity function
    mt.__index = {
        IsA = function() return "Symbol" end,
        ClassName = "Symbol",
    }
    return symbol
end

return Symbol.new