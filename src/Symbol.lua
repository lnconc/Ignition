--!native

local SymbolAPI = {}

--[=[
@within Symbol
@param other Symbol | string
@return boolean
Compare 2 symbols if both contexes are the same.
]=]
function SymbolAPI:matches(other: Symbol | string): boolean
	local symbol = getmetatable(self)
	return if type(other) == "string" then other == symbol else getmetatable(other) == symbol
end

--[=[
@within Symbol
@return string
Retrieve the context applied to the symbol.
]=]
function SymbolAPI:getcontext(): string
    return getmetatable(self)
end

--[=[
@class Symbol
@__index SymbolAPI
Unique identifiers, uses `newproxy()`.
]=]
local function makeSymbol(context: string): Symbol
    assert(type(context) == "string", "Argument 1 expects a string")
    assert(#context > 0, "Argument 1 expects a non-empty string")
	local proxy = newproxy(true)
	local mt = getmetatable(proxy)
	mt.__tostring = function()
		return `Symbol<{context}>`
	end
	mt.__metatable = context
	mt.__index = SymbolAPI
	return proxy
end

type Symbol = typeof(makeSymbol("TestSymbol"))
return makeSymbol