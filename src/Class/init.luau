--!strict
-- Class.lua

local abstract = require("@self/Libs/abstract")
local anon = require("@self/Libs/anon")
local class = require("@self/Libs/class")
local delete = require("@self/Libs/delete")
local dumpsize = require("@self/Libs/dumpsize")
local extends = require("@self/Libs/extends")
local final = require("@self/Libs/final")
local free = require("@self/Libs/free")
local friend = require("@self/Libs/friend")
local import = require("@self/Libs/import")
local mixin = require("@self/Libs/mixin")
local new = require("@self/Libs/new")
local nullable = require("@self/Libs/nullable")
local property = require("@self/Libs/property")
local reactive = require("@self/Libs/reactive")
local ref = require("@self/Libs/ref")
local super = require("@self/Libs/super")
local func = require("@self/Libs/func")
local mutual = require("@self/Libs/mutual")
local union = require("@self/Libs/union")
local Log = require("./Log")
local Configuration = require("@self/Utility/Configuration")
local Types = require("@self/Types")

type Class = Types.Class

local Class = {
    extends = extends,
    class = class,
    abstract = abstract,
    final = final,
    mixin = mixin,
    import = import,
    ref = ref,
    super = super,
    property = property,
    new = new,
    reactive = reactive,
    nullable = nullable,
    func = func,
    union = union,
    free = free,
    anon = anon,
    dumpsize = dumpsize,
    delete = delete,
    friend = friend,
    mutual = mutual,
    PLACEHOLDER = Configuration.PLACEHOLDER,
    FLAGS = table.freeze(Configuration.PROPERTY_FLAGS),
    PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED,
    METADATA = Configuration.METADATA,
}

function Class.unwrap<I>(target: I): I
    return target
end

function Class.from(...: string): ...any
    local retrieved = table.pack(...)
    for i = 1, retrieved.n do
        local k = retrieved[i]
        local r = (Class :: any)[k]
        if not r then
            Log.CANNOT_FIND_FROM:throw(2, k)
        end
        retrieved[i] = r
    end
    return table.unpack(retrieved)
end

return table.freeze(Class) :: Class