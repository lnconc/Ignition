--!strict
-- CLass/Libs/func.lua

local Types = require("../Types")
local property = require("./property")

type Symbol<T> = Types.Symbol<T>
type FinalProperty<P> = Types.FinalProperty<P>
type PropertyExposure = Types.PropertyExposure

type FuncOptions = { exposure: PropertyExposure?, flags: { Symbol<string> }? } | any

local function func(options: FuncOptions): FinalProperty<any>
    return property({ flags = options.flags, exposure = options.exposure or "shared", type = "function" } :: any) :: any
end

return func