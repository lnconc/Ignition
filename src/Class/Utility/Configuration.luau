--!nocheck
-- Class/Utility/Configuration.lua

local Symbol = require("../../Symbol")
local function symbol<T>(id: T): Symbol.Symbol<T>
    return Symbol(id)
end

local FORCE_PRODUCTION_MODE = false

return {
    PRODUCTION_MODE_ENABLED = not game:GetService("RunService"):IsStudio() or FORCE_PRODUCTION_MODE,
    MAX_STACK_DEPTH = 10,
    HEADER_EXTENSION = ".definition",
    PROPERTY_SIGNATURE = "$property",
    NULLABLE_SIGNATURE = "$nullable",
    UNION_SIGNATURE = "$union",
    METADATA = symbol("metadata"),
    PLACEHOLDER = symbol("placeholder"),
    PROPERTY_FLAGS = {
        Optional = symbol("optional"),
        Static = symbol("static"),
        Constant = symbol("constant"),
        Virtual = symbol("virtual"),
        Readonly = symbol("readonly"),
        Reactive = symbol("reactive"),
    }
}