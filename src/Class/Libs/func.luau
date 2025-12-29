--!strict
-- CLass/Libs/func.lua

local Types = require("../Types")
local prop = require("./prop")

type Symbol<T> = Types.Symbol<T>
type Property<P> = Types.Property<P>

type FuncOptions = { exposure: string?, flags: { Symbol<string> }? } | any

local function func(options: FuncOptions): Property<any>
    return prop({ value = nil, flags = options.flags, exposure = options.exposure or "shared", type = "function" } :: any) :: any
end

return func