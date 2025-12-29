--!strict
-- CLass/Libs/property.lua

local Types = require("../Types")
local prop = require("./prop")

type Symbol<T> = Types.Symbol<T>
type Property<P> = Types.Property<P>

type PropertyOptions = {
    exposure: string?,
    flags: { Symbol<string>? },
    value: any?,
    type: string?,
} | any

local function property<P>(options: PropertyOptions): Property<P>
    return prop({ value = options.value, flags = options.flags, exposure = options.exposure or "shared", type = options.type } :: any) :: any
end

return property